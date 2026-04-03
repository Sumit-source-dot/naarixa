import 'dart:convert';
import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

final renterPopularPropertiesProvider = FutureProvider<List<RenterProperty>>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    final response = await supabase.from('property').select();

    if (response.isEmpty) {
      return const [];
    }

    final rows = response.cast<Map<String, dynamic>>();

    final ownerIds = rows
        .map((row) => (row['ownerid'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final ownerDirectory = <String, Map<String, dynamic>>{};
    if (ownerIds.isNotEmpty) {
      try {
        final owners = await supabase
            .from('profiles')
          .select('id, full_name, name, phone, email, avatar_url, image_url, profile_image_url')
            .inFilter('id', ownerIds);

        for (final owner in (owners as List)) {
          final profile = owner as Map<String, dynamic>;
          final id = (profile['id'] ?? '').toString().trim();
          if (id.isNotEmpty) {
            ownerDirectory[id] = profile;
          }
        }
      } catch (_) {
        // Continue rendering properties even if owner profile lookup fails.
      }
    }

    final mapped = rows
        .map((row) => _mapToRenterProperty(row, ownerDirectory))
        .whereType<RenterProperty>()
        .toList();

    mapped.sort((a, b) => b.rating.compareTo(a.rating));
    return mapped;
  } on PostgrestException catch (e) {
    final code = (e.code ?? '').toUpperCase();
    if (code == '42501') {
      throw Exception('Property read blocked by RLS policy (code 42501).');
    }
    throw Exception('Property query failed: ${e.message}');
  } catch (e) {
    throw Exception('Unexpected property fetch error: $e');
  }
});

RenterProperty? _mapToRenterProperty(
  Map<String, dynamic> row,
  Map<String, Map<String, dynamic>> ownerDirectory,
) {
  final title = _resolvePropertyTitle(row);

  final location =
      (row['location'] ?? row['city'] ?? row['address'] ?? '').toString().trim();
  final propertyType =
      (row['propertytype'] ?? row['propertyType'] ?? row['property_type'] ?? 'Home')
          .toString()
          .trim();

  final budgetRaw = row['budget'];
  final budget = budgetRaw is num ? budgetRaw.toDouble() : double.tryParse('$budgetRaw') ?? 0;
  final priceLabel = budget > 0
      ? 'INR ${budget.toStringAsFixed(0)}/mo'
      : 'Price on request';

  final rating = _deriveRating(row);
  final reviews = _deriveReviews(row);
  final tags = _extractTags(row, propertyType);
  final verified = row['verified'] == true || row['verification_status'] == 1;

  final idSeed = (row['id'] ?? title).toString();
  final ownerId = (row['ownerid'] ?? '').toString().trim();
  final ownerProfile = ownerId.isEmpty ? null : ownerDirectory[ownerId];
  final ownerName = _resolveOwnerName(ownerProfile, row, ownerId);

  final bedrooms = _asNullableInt(row['bedrooms']);
  final bathrooms = _asNullableInt(row['bathrooms']);
  final area = _asNullableDouble(row['area']);
  final postedAt = _asNullableDateTime(row['createdat'] ?? row['created_at']);

  return RenterProperty(
    id: (row['id'] ?? '').toString(),
    name: title,
    location: location.isEmpty ? 'Location not specified' : location,
    price: priceLabel,
    monthlyRent: budget > 0 ? budget : null,
    ownerId: ownerId.isEmpty ? null : ownerId,
    ownerName: ownerName.isEmpty ? 'Owner' : ownerName,
    ownerImageUrl: _resolveOwnerImage(ownerProfile, row),
    imageUrl: _extractPropertyImage(row),
    ownerPhone: _asNullableText(ownerProfile?['phone'] ?? row['owner_phone']),
    ownerEmail: _asNullableText(ownerProfile?['email'] ?? row['owner_email']),
    type: propertyType.isEmpty ? 'Home' : propertyType,
    bedrooms: bedrooms,
    bathrooms: bathrooms,
    area: area,
    postedAt: postedAt,
    rating: rating,
    reviews: reviews,
    tags: tags,
    gradient: _pickGradient(idSeed),
    isVerified: verified,
  );
}

String? _resolveOwnerImage(
  Map<String, dynamic>? ownerProfile,
  Map<String, dynamic> propertyRow,
) {
  return _asNullableText(
    ownerProfile?['avatar_url'] ??
        ownerProfile?['image_url'] ??
        ownerProfile?['profile_image_url'] ??
        propertyRow['owner_avatar_url'] ??
        propertyRow['owner_image_url'],
  );
}

String _resolveOwnerName(
  Map<String, dynamic>? ownerProfile,
  Map<String, dynamic> propertyRow,
  String ownerId,
) {
  final fromProfile = (ownerProfile?['full_name'] ?? '').toString().trim();
  if (fromProfile.isNotEmpty) {
    return fromProfile;
  }

  final fromProfileName = (ownerProfile?['name'] ?? '').toString().trim();
  if (fromProfileName.isNotEmpty) {
    return fromProfileName;
  }

  final fromProperty =
      (propertyRow['owner_name'] ?? propertyRow['ownername'] ?? '').toString().trim();
  if (fromProperty.isNotEmpty) {
    return fromProperty;
  }

  final email = (ownerProfile?['email'] ?? '').toString().trim();
  if (email.contains('@')) {
    final local = email.split('@').first.trim();
    if (local.isNotEmpty) {
      return local;
    }
  }

  if (ownerId.isNotEmpty && ownerId.length >= 6) {
    return 'Owner ${ownerId.substring(0, 6)}';
  }

  return 'Owner';
}

String? _asNullableText(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _asNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _asNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _asNullableDateTime(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

String _resolvePropertyTitle(Map<String, dynamic> row) {
  final directTitle =
      (row['title'] ?? row['name'] ?? row['property_name'] ?? '').toString().trim();
  if (directTitle.isNotEmpty) {
    return directTitle;
  }

  final propertyType =
      (row['propertytype'] ?? row['propertyType'] ?? row['property_type'] ?? 'Home')
          .toString()
          .trim();
  final location =
      (row['location'] ?? row['city'] ?? row['address'] ?? 'Local Area').toString().trim();

  return '$propertyType in $location';
}

List<String> _extractTags(Map<String, dynamic> row, String propertyType) {
  final tags = <String>[];

  final amenitiesRaw = row['amenities'];
  if (amenitiesRaw is List) {
    for (final item in amenitiesRaw) {
      final value = item.toString().trim();
      if (value.isNotEmpty) {
        tags.add(value);
      }
    }
  } else if (amenitiesRaw is String) {
    final value = amenitiesRaw.trim();
    if (value.startsWith('[') && value.endsWith(']')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          for (final item in decoded) {
            final parsed = item.toString().trim();
            if (parsed.isNotEmpty) {
              tags.add(parsed);
            }
          }
        }
      } catch (_) {}
    }
  }

  final bedrooms = row['bedrooms'];
  if (bedrooms is num && bedrooms > 0) {
    tags.add('${bedrooms.toInt()} BHK');
  }

  if (row['womenfriendly'] == true || row['women_friendly'] == true) {
    tags.add('Women Friendly');
  }

  if (tags.isEmpty && propertyType.isNotEmpty) {
    tags.add(propertyType);
  }

  if (tags.isEmpty) {
    tags.add('Available');
  }

  return tags.take(3).toList();
}

String _extractPropertyImage(Map<String, dynamic> row) {
  final dynamic raw = row['images'] ?? row['image'] ?? row['image_url'];
  if (raw == null) return '';

  if (raw is List) {
    for (final item in raw) {
      final value = _sanitizeImageUrl(item?.toString());
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  if (raw is String) {
    final value = raw.trim();
    if (value.isEmpty) return '';

    if (value.startsWith('[')) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is List) {
          for (final item in decoded) {
            final url = _sanitizeImageUrl(item?.toString());
            if (url.isNotEmpty) return url;
          }
        }
      } catch (_) {
        final fallback = _extractFirstHttpUrl(value);
        return _sanitizeImageUrl(fallback ?? value);
      }
      return '';
    }

    if (value.startsWith('{') && value.endsWith('}')) {
      final trimmed = value.substring(1, value.length - 1);
      for (final part in trimmed.split(',')) {
        final url = part.trim();
        if (url.isNotEmpty) return url;
      }
      return '';
    }

    final fallback = _extractFirstHttpUrl(value);
    return _sanitizeImageUrl(fallback ?? value);
  }

  return '';
}

String? _extractFirstHttpUrl(String input) {
  final match = RegExp(r'https?://[^\s"\]\[]+').firstMatch(input);
  return match?.group(0);
}

String _sanitizeImageUrl(String? raw) {
  if (raw == null) return '';

  var value = raw.trim();
  if (value.isEmpty) return '';

  if ((value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))) {
    value = value.substring(1, value.length - 1).trim();
  }

  value = value
      .replaceAll(r'\/', '/')
      .replaceAll(r'\\/', '/')
      .replaceAll('\\u0026', '&')
      .replaceAll('\u0026', '&')
      .replaceAll('\"', '');

  value = value.replaceFirst(RegExp(r'[,;]+$'), '');

  final uri = Uri.tryParse(value);
  if (uri == null || !(uri.hasScheme && uri.hasAuthority)) return '';

  return value;
}

double _deriveRating(Map<String, dynamic> row) {
  final safety = row['safetyscore'] ?? row['safety_score'];
  if (safety is num) {
    final mapped = 3.5 + (safety.clamp(0, 100) / 100) * 1.5;
    return double.parse(mapped.toStringAsFixed(1));
  }
  return 4.5;
}

int _deriveReviews(Map<String, dynamic> row) {
  final area = row['area'];
  if (area is num) {
    final value = (area / 100).round();
    return value < 5 ? 5 : value;
  }
  return 12;
}

List<Color> _pickGradient(String seed) {
  const palettes = [
    [Color(0xFFFFD89B), Color(0xFF19547B)],
    [Color(0xFF96FBC4), Color(0xFF3E8D63)],
    [Color(0xFFBDE0FE), Color(0xFF4895EF)],
    [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
    [Color(0xFFFCCF31), Color(0xFFF55555)],
    [Color(0xFF84FAB0), Color(0xFF8FD3F4)],
  ];

  final hash = seed.codeUnits.fold<int>(0, (prev, c) => prev + c);
  return palettes[hash % palettes.length];
}
