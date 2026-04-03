import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';

final accommodationFilterProvider = StateProvider<String>((ref) => 'all');

class OwnerProperty {
  final String id;
  final String title;
  final String description;
  final String location;
  final String propertyType; // Apartment, PG/Co-Living, Plot, etc.
  final double budget;
  final int? bedrooms;
  final int? bathrooms;
  final double? area;
  final List<String> images; // Array of image URLs
  final bool womenFriendly;
  final List<String> amenities; // Array of amenities
  final int verificationStatus; // 0 = not verified, 1 = verified
  final bool isActive;
  final Map<String, double>? geo; // { "lat": x, "lng": y }
  final int safetyScore; // 0-100, default 0
  final String? verificationProof; // Optional proof/certificate for property verification

  OwnerProperty({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.propertyType,
    required this.budget,
    this.bedrooms,
    this.bathrooms,
    this.area,
    this.images = const [],
    this.womenFriendly = false,
    this.amenities = const [],
    this.verificationStatus = 0,
    this.isActive = true,
    this.geo,
    this.safetyScore = 0,
    this.verificationProof,
  });

  factory OwnerProperty.fromMap(Map<String, dynamic> map) {
    final rawImages = map['images'];
    List<String> parsedImages;
    if (rawImages is List) {
      parsedImages = rawImages
          .map((e) => e.toString().trim().replaceAll('"', ''))
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (rawImages is String) {
      final value = rawImages.trim();
      if (value.isEmpty) {
        parsedImages = const [];
      } else if (value.startsWith('[') && value.endsWith(']')) {
        // Handles JSON string array format: ["url1", "url2"]
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            parsedImages = decoded
                .map((e) => e.toString().trim().replaceAll('"', ''))
                .where((e) => e.isNotEmpty)
                .toList();
          } else {
            parsedImages = const [];
          }
        } catch (_) {
          parsedImages = const [];
        }
      } else if (value.startsWith('{') && value.endsWith('}')) {
        // Handles postgres text[] string format: {url1,url2}
        final inner = value.substring(1, value.length - 1);
        parsedImages = inner
            .split(',')
            .map((e) => e.trim().replaceAll('"', ''))
            .where((e) => e.isNotEmpty)
            .toList();
      } else {
        parsedImages = [value.replaceAll('"', '')];
      }
    } else {
      parsedImages = const [];
    }

    if (parsedImages.isEmpty) {
      final fallback = (map['imageurl'] ?? map['image_url'] ?? '').toString().trim();
      if (fallback.isNotEmpty) {
        parsedImages = [fallback];
      }
    }

    return OwnerProperty(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      propertyType: map['propertytype'] ?? map['propertyType'] ?? map['property_type'] ?? 'Apartment',
      budget: (map['budget'] ?? 0).toDouble(),
      bedrooms: map['bedrooms'],
      bathrooms: map['bathrooms'],
      area: map['area'] != null ? (map['area'] as num).toDouble() : null,
      images: parsedImages,
      womenFriendly: map['womenfriendly'] ?? map['womenFriendly'] ?? map['women_friendly'] ?? false,
      amenities: List<String>.from(map['amenities'] ?? []),
      verificationStatus: map['verified'] == true ? 1 : 0,
      isActive: map['status'] != 'Occupied' && map['status'] != 'Pending',
      geo: map['geo'] != null ? Map<String, double>.from(map['geo']) : null,
      safetyScore: map['safetyscore'] ?? map['safetyScore'] ?? map['safety_score'] ?? 0,
      verificationProof: map['verification_proof'] ?? map['verificationproof'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'propertytype': propertyType,
      'budget': budget,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'images': images,
      'womenfriendly': womenFriendly,
      'amenities': amenities,
      'verified': verificationStatus == 1,
      'status': isActive ? 'Available' : 'Pending',
      'geo': geo,
      'safetyscore': safetyScore,
      'verification_proof': verificationProof,
    };
  }

  OwnerProperty copyWith({
    int? verificationStatus,
  }) {
    return OwnerProperty(
      id: id,
      title: title,
      description: description,
      location: location,
      propertyType: propertyType,
      budget: budget,
      bedrooms: bedrooms,
      bathrooms: bathrooms,
      area: area,
      images: images,
      womenFriendly: womenFriendly,
      amenities: amenities,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isActive: isActive,
      geo: geo,
      safetyScore: safetyScore,
      verificationProof: verificationProof,
    );
  }
}

// Fetch owner's properties from Supabase
final ownerPropertiesProvider = FutureProvider<List<OwnerProperty>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    return [];
  }

  try {
    final response = await supabase
        .from('property')
        .select()
        .eq('ownerid', user.id)
        .order('createdat', ascending: false);

    if (response.isEmpty) {
      return [];
    }

    final properties =
        (response as List).map((p) => OwnerProperty.fromMap(p as Map<String, dynamic>)).toList();

    final propertyIds = properties
        .map((property) => property.id)
        .where((id) => id.trim().isNotEmpty)
        .toList();

    if (propertyIds.isEmpty) {
      return properties;
    }

    final latestStatusByProperty = <String, String>{};

    try {
      final verificationRows = await supabase
          .from('property_verifications')
          .select('property_id, verification_status, status, created_at')
          .inFilter('property_id', propertyIds)
          .order('created_at', ascending: false);

      for (final row in (verificationRows as List)) {
        final map = row as Map<String, dynamic>;
        final propertyId = map['property_id']?.toString().trim() ?? '';
        if (propertyId.isEmpty || latestStatusByProperty.containsKey(propertyId)) {
          continue;
        }

        final verificationStatus =
            map['verification_status']?.toString().trim().toLowerCase() ??
                map['status']?.toString().trim().toLowerCase() ??
                'pending';

        latestStatusByProperty[propertyId] = verificationStatus;
      }
    } catch (_) {
      return properties;
    }

    return properties.map((property) {
      final verificationStatus = latestStatusByProperty[property.id];
      if (verificationStatus == null) {
        return property;
      }

      return property.copyWith(
        verificationStatus: verificationStatus == 'approved' ? 1 : 0,
      );
    }).toList();
  } catch (e) {
    if (e is PostgrestException && e.code == '42704') {
      // Database side policy/function is referencing a missing custom setting.
      return [];
    }
    print('Error fetching properties: $e');
    return [];
  }
});

// Provider to count stats
final ownerPropertiesStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final properties = await ref.watch(ownerPropertiesProvider.future);

  return {
    'total': properties.length,
    'verified': properties.where((p) => p.verificationStatus == 1).length,
    'available': properties.where((p) => p.isActive).length,
  };
});

// Delete property
final deletePropertyProvider = FutureProvider.family<bool, String>((ref, propertyId) async {
  final supabase = Supabase.instance.client;

  try {
    await supabase.from('property').delete().eq('id', propertyId);
    // Refresh the properties list after deletion
    ref.refresh(ownerPropertiesProvider);
    return true;
  } catch (e) {
    print('Error deleting property: $e');
    return false;
  }
});

// Update property
final updatePropertyProvider =
    FutureProvider.family<bool, (String, OwnerProperty)>((ref, params) async {
  final (propertyId, updatedProperty) = params;
  final supabase = Supabase.instance.client;

  try {
    await supabase
        .from('property')
        .update(updatedProperty.toMap())
        .eq('id', propertyId);
    // Refresh the properties list after update
    ref.refresh(ownerPropertiesProvider);
    return true;
  } catch (e) {
    print('Error updating property: $e');
    return false;
  }
});

// Provider to check if user is verified
final userVerificationProvider = FutureProvider<bool>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    return false;
  }

  try {
    // Prefer profiles table; if schema doesn't have the field, fallback to auth status.
    final response = await supabase
        .from('profiles')
        .select('is_verified')
        .eq('id', user.id)
        .maybeSingle();

    final profileVerified = response?['is_verified'];
    if (profileVerified is bool) {
      return profileVerified;
    }
  } catch (e) {
    // Ignore schema/table errors and fallback below.
  }

  // Fallback: treat contact-verified users as verified in banner logic.
  return user.emailConfirmedAt != null && user.phoneConfirmedAt != null;
});

class VerificationProgressStatus {
  const VerificationProgressStatus({
    required this.emailVerified,
    required this.personalPhoneVerified,
    required this.emergencyPhoneVerified,
    required this.governmentIdVerified,
  });

  final bool emailVerified;
  final bool personalPhoneVerified;
  final bool emergencyPhoneVerified;
  final bool governmentIdVerified;

  int get totalItems => 4;

  int get completedItems {
    var completed = 0;
    if (emailVerified) completed++;
    if (personalPhoneVerified) completed++;
    if (emergencyPhoneVerified) completed++;
    if (governmentIdVerified) completed++;
    return completed;
  }

  double get progress => completedItems / totalItems;

  int get percent => (progress * 100).round();

  bool get fullyVerified => completedItems == totalItems;
}

final verificationProgressProvider = FutureProvider<VerificationProgressStatus>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  if (user == null) {
    return const VerificationProgressStatus(
      emailVerified: false,
      personalPhoneVerified: false,
      emergencyPhoneVerified: false,
      governmentIdVerified: false,
    );
  }

  final emailVerified = user.emailConfirmedAt != null;
  var personalPhoneVerified = user.phoneConfirmedAt != null;

  var emergencyPhoneVerified = false;
  var governmentIdVerified = false;

  try {
    final profile = await supabase
        .from('profiles')
        .select('emergency_contact_verified, phone_verified')
        .eq('id', user.id)
        .maybeSingle();

    final profilePhoneVerified = profile?['phone_verified'];
    if (profilePhoneVerified is bool) {
      personalPhoneVerified = profilePhoneVerified;
    }
    emergencyPhoneVerified = profile?['emergency_contact_verified'] == true;
  } catch (_) {
    emergencyPhoneVerified = false;
  }

  try {
    final ownerProperties = await supabase
        .from('property')
        .select('id')
        .eq('ownerid', user.id)
        .limit(20);

    final propertyIds = (ownerProperties as List)
        .map((row) => row['id']?.toString())
        .whereType<String>()
        .toList();

    if (propertyIds.isNotEmpty) {
      final verificationRows = await supabase
          .from('property_verifications')
          .select('verification_status, status')
          .inFilter('property_id', propertyIds)
          .order('created_at', ascending: false)
          .limit(10);

      governmentIdVerified = (verificationRows as List).any(
        (row) {
          final map = row as Map<String, dynamic>;
          final status = (map['verification_status']?.toString().toLowerCase() ??
              map['status']?.toString().toLowerCase() ??
              '');
          return status == 'approved';
        },
      );
    }
  } catch (_) {
    governmentIdVerified = false;
  }

  return VerificationProgressStatus(
    emailVerified: emailVerified,
    personalPhoneVerified: personalPhoneVerified,
    emergencyPhoneVerified: emergencyPhoneVerified,
    governmentIdVerified: governmentIdVerified,
  );
});

class ContactVerificationStatus {
  const ContactVerificationStatus({
    required this.emailVerified,
    required this.phoneVerified,
  });

  final bool emailVerified;
  final bool phoneVerified;

  bool get bothUnverified => !emailVerified && !phoneVerified;
}

final contactVerificationProvider = Provider<ContactVerificationStatus>((ref) {
  final user = Supabase.instance.client.auth.currentUser;
  return ContactVerificationStatus(
    emailVerified: user?.emailConfirmedAt != null,
    phoneVerified: user?.phoneConfirmedAt != null,
  );
});

class PropertyVerificationPayload {
  const PropertyVerificationPayload({
    required this.propertyId,
    required this.ownershipDocumentUrl,
    required this.utilityBillUrl,
    required this.otherRequiredDocumentUrl,
  });

  final String propertyId;
  final String ownershipDocumentUrl;
  final String utilityBillUrl;
  final String otherRequiredDocumentUrl;
}

final submitPropertyVerificationProvider =
    FutureProvider.family<bool, PropertyVerificationPayload>((ref, payload) async {
  final supabase = Supabase.instance.client;

  try {
    const status = 'pending';

    await supabase.from('property_verifications').insert({
      'property_id': payload.propertyId,
      'ownership_document_url': payload.ownershipDocumentUrl.trim(),
      'utility_bill_url': payload.utilityBillUrl.trim(),
      'other_required_document_url': payload.otherRequiredDocumentUrl.trim(),
      'verification_status': status,
      // Backward compatibility for existing consumers.
      'status': status,
      'document_type': 'ownership_document',
      'document_url': payload.ownershipDocumentUrl.trim(),
    });

    ref.invalidate(ownerPropertiesProvider);
    ref.invalidate(ownerPropertiesStatsProvider);
    ref.invalidate(verificationProgressProvider);
    return true;
  } catch (e) {
    print('Error submitting property verification: $e');
    return false;
  }
});