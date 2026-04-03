import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';

class ProfileUiState {
  const ProfileUiState({required this.name, required this.email, required this.imageUrl});

  final String name;
  final String email;
  final String imageUrl;

  ProfileUiState copyWith({String? name, String? email, String? imageUrl}) {
    return ProfileUiState(
      name: name ?? this.name,
      email: email ?? this.email,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}

class ProfileController extends StateNotifier<ProfileUiState> {
  ProfileController() : super(_fromUser(SupabaseService.client.auth.currentUser)) {
    _authSubscription = SupabaseService.client.auth.onAuthStateChange.listen((event) {
      state = _fromUser(event.session?.user);
    });
  }

  static const String _defaultAvatar = 'https://i.pravatar.cc/150?img=32';

  StreamSubscription<AuthState>? _authSubscription;

  static ProfileUiState _fromUser(User? user) {
    final email = user?.email?.trim() ?? '';
    final metadata = user?.userMetadata ?? const <String, dynamic>{};
    final imageUrl = (metadata['avatar_url'] as String?)?.trim() ?? _defaultAvatar;

    final rawName = (metadata['full_name'] as String?)?.trim() ??
        (metadata['name'] as String?)?.trim() ??
        '';

    final fallbackName = email.isEmpty
      ? 'Naarixa User'
        : email.split('@').first.replaceAll('.', ' ').replaceAll('_', ' ').trim();

    return ProfileUiState(
      name: rawName.isEmpty ? fallbackName : rawName,
      email: email,
      imageUrl: imageUrl.isEmpty ? _defaultAvatar : imageUrl,
    );
  }

  Future<void> updateName(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return;

    await _updateUserMetadata({'full_name': trimmedName});
    state = state.copyWith(name: trimmedName);
  }

  Future<void> updateProfileImage(String imageUrl) async {
    final trimmedUrl = imageUrl.trim();
    if (trimmedUrl.isEmpty) return;

    await _updateUserMetadata({'avatar_url': trimmedUrl});
    state = state.copyWith(imageUrl: trimmedUrl);
  }

  Future<void> _updateUserMetadata(Map<String, dynamic> values) async {
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser == null) {
      return;
    }

    final merged = <String, dynamic>{
      ...(currentUser.userMetadata ?? const <String, dynamic>{}),
      ...values,
    };

    await SupabaseService.client.auth.updateUser(UserAttributes(data: merged));
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final profileUiStateProvider = StateNotifierProvider<ProfileController, ProfileUiState>(
  (ref) => ProfileController(),
);

class ProfessionalDetailsState {
  const ProfessionalDetailsState({
    this.ownerType = 'Individual',
    this.renterType = 'student',
    this.yearsOfExperience,
    this.city,
    this.emergencyContact,
    this.idType,
    this.idNumberMasked,
    this.idDocumentUrl,
    this.companyName,
    this.gstNumber,
    this.cinNumber,
    this.authorizedPersonName,
    this.authorizedPersonPan,
    this.brokerAgencyName,
    this.brokerReraNumber,
    this.brokerLicenseNumber,
    this.landlordBusinessName,
    this.landlordTotalPropertiesOwned,
    this.landlordPanNumber,
    this.individualOccupation,
    this.individualAddress,
    this.individualPanNumber,
    this.individualAadhaarLast4,
    this.studentCollegeName,
    this.studentCourseYear,
    this.studentCollegeId,
    this.studentGuardianName,
    this.studentGuardianPhone,
    this.workingCompanyName,
    this.workingJobTitle,
    this.workingOfficeAddress,
    this.workingWorkEmail,
    this.selfEmployedBusinessName,
    this.selfEmployedNatureOfWork,
    this.selfEmployedOfficeAddress,
    this.propertyId,
    this.verificationStatus = 'pending',
    this.emergencyContactVerified = false,
  });

  final String ownerType;
  final String renterType;
  final int? yearsOfExperience;
  final String? city;
  final String? emergencyContact;
  final String? idType;
  final String? idNumberMasked;
  final String? idDocumentUrl;
  final String? companyName;
  final String? gstNumber;
  final String? cinNumber;
  final String? authorizedPersonName;
  final String? authorizedPersonPan;
  final String? brokerAgencyName;
  final String? brokerReraNumber;
  final String? brokerLicenseNumber;
  final String? landlordBusinessName;
  final int? landlordTotalPropertiesOwned;
  final String? landlordPanNumber;
  final String? individualOccupation;
  final String? individualAddress;
  final String? individualPanNumber;
  final String? individualAadhaarLast4;
  final String? studentCollegeName;
  final String? studentCourseYear;
  final String? studentCollegeId;
  final String? studentGuardianName;
  final String? studentGuardianPhone;
  final String? workingCompanyName;
  final String? workingJobTitle;
  final String? workingOfficeAddress;
  final String? workingWorkEmail;
  final String? selfEmployedBusinessName;
  final String? selfEmployedNatureOfWork;
  final String? selfEmployedOfficeAddress;
  final String? propertyId;
  final String verificationStatus;
  final bool emergencyContactVerified;
}

class ProfessionalDetailsController {
  final _client = SupabaseService.client;
  static bool _ownerProfessionalTableMissing = false;
  static bool _renterStudentTableMissing = false;
  static bool _renterWorkingTableMissing = false;
  static bool _renterSelfEmployedTableMissing = false;

  bool _isMissingTableOrColumnError(PostgrestException error) {
    final code = (error.code ?? '').toUpperCase();
    final message = error.message.toLowerCase();
    return code == 'PGRST205' ||
        code == '42703' ||
        message.contains('could not find the table') ||
        message.contains('relation') && message.contains('does not exist') ||
        message.contains('column') && message.contains('does not exist');
  }

  Future<String?> _getOwnerPropertyId(String ownerId) async {
    final rows = await _client
        .from('property')
        .select('id')
        .eq('ownerid', ownerId)
        .order('createdat', ascending: false)
        .limit(1);

    if (rows.isNotEmpty) {
      final id = rows.first['id'];
      return id?.toString();
    }
    return null;
  }

  Future<ProfessionalDetailsState> fetch() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const ProfessionalDetailsState();
    }

    final propertyId = await _getOwnerPropertyId(user.id);

    Map<String, dynamic>? profile;
    try {
      profile = await _client.from('profiles').select().eq('id', user.id).maybeSingle();
    } catch (_) {
      profile = null;
    }

    Map<String, dynamic>? professional;
    if (!_ownerProfessionalTableMissing) {
      try {
        professional = await _client
            .from('owner_professional_details')
            .select()
            .eq('owner_id', user.id)
            .maybeSingle();
      } on PostgrestException catch (error) {
        if ((error.code ?? '').toUpperCase() == 'PGRST205') {
          _ownerProfessionalTableMissing = true;
        }
        professional = null;
      } catch (_) {
        professional = null;
      }
    }

    Map<String, dynamic>? ownerDetails;
    try {
      ownerDetails = await _client
          .from('owner_details')
          .select('owner_type, verification_status')
          .eq('owner_id', user.id)
          .maybeSingle();
    } catch (_) {
      ownerDetails = null;
    }

    Map<String, dynamic>? verification;
    if (propertyId != null) {
      try {
        verification = await _client
            .from('property_verifications')
            .select(
              'document_type, document_url, ownership_document_url, utility_bill_url, verification_status, status',
            )
            .eq('property_id', propertyId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();
      } catch (_) {
        verification = null;
      }
    }

    Map<String, dynamic>? ownerVerification;
    try {
      ownerVerification = await _client
          .from('owner_verifications')
          .select()
          .eq('owner_id', user.id)
          .maybeSingle();
    } catch (_) {
      ownerVerification = null;
    }

    Map<String, dynamic>? renterVerification;
    try {
      renterVerification = await _client
          .from('renter_verifications')
          .select()
          .eq('renter_id', user.id)
          .maybeSingle();
    } catch (_) {
      renterVerification = null;
    }

    Map<String, dynamic>? companyOwners;
    try {
      companyOwners = await _client
          .from('company_owners')
          .select()
          .eq('owner_id', user.id)
          .maybeSingle();
    } catch (_) {
      companyOwners = null;
    }

    Map<String, dynamic>? brokerOwners;
    try {
      brokerOwners = await _client
          .from('broker_owners')
          .select()
          .eq('owner_id', user.id)
          .maybeSingle();
    } catch (_) {
      brokerOwners = null;
    }

    Map<String, dynamic>? professionalLandlords;
    try {
      professionalLandlords = await _client
          .from('professional_landlords')
          .select()
          .eq('owner_id', user.id)
          .maybeSingle();
    } catch (_) {
      professionalLandlords = null;
    }

    Map<String, dynamic>? individualOwners;
    try {
      individualOwners = await _client
          .from('individual_owners')
          .select()
          .eq('owner_id', user.id)
          .maybeSingle();
    } catch (_) {
      individualOwners = null;
    }

    Map<String, dynamic>? renterStudent;
    if (!_renterStudentTableMissing) {
      try {
        renterStudent = await _client
            .from('renter_students')
            .select()
            .eq('renter_id', user.id)
            .maybeSingle();
      } on PostgrestException catch (error) {
        if (_isMissingTableOrColumnError(error)) {
          _renterStudentTableMissing = true;
        }
        renterStudent = null;
      } catch (_) {
        renterStudent = null;
      }
    }

    Map<String, dynamic>? renterWorking;
    if (!_renterWorkingTableMissing) {
      try {
        renterWorking = await _client
            .from('renter_working_professionals')
            .select()
            .eq('renter_id', user.id)
            .maybeSingle();
      } on PostgrestException catch (error) {
        if (_isMissingTableOrColumnError(error)) {
          _renterWorkingTableMissing = true;
        }
        renterWorking = null;
      } catch (_) {
        renterWorking = null;
      }
    }

    Map<String, dynamic>? renterSelfEmployed;
    if (!_renterSelfEmployedTableMissing) {
      try {
        renterSelfEmployed = await _client
            .from('renter_self_employed')
            .select()
            .eq('renter_id', user.id)
            .maybeSingle();
      } on PostgrestException catch (error) {
        if (_isMissingTableOrColumnError(error)) {
          _renterSelfEmployedTableMissing = true;
        }
        renterSelfEmployed = null;
      } catch (_) {
        renterSelfEmployed = null;
      }
    }

      final role = (profile?['role'] as String?)?.trim().toLowerCase() ?? '';
      final isRenter = role == 'renter';

      final ownerVerificationStatusRaw =
        (ownerVerification?['status'] as String?)?.trim().toLowerCase();
      final ownerVerificationStatus =
        ownerVerificationStatusRaw == 'verified' ? 'approved' : ownerVerificationStatusRaw;
      final ownerVerificationApproved = ownerVerification?['id_verified'] == true;
      final ownerDetailsStatus =
        (ownerDetails?['verification_status'] as String?)?.trim().toLowerCase();
      final propertyVerificationStatus =
        ((verification?['verification_status'] as String?) ??
            (verification?['status'] as String?))
          ?.trim()
          .toLowerCase();

      final renterVerificationStatusRaw =
        ((renterVerification?['verification_status'] as String?) ??
            (renterVerification?['status'] as String?))
          ?.trim()
          .toLowerCase();
      final renterVerificationApproved =
        (renterVerification?['is_verified'] == true) ||
        renterVerificationStatusRaw == 'verified' ||
        renterVerificationStatusRaw == 'approved';

      final resolvedVerificationStatus = isRenter
        ? (renterVerificationApproved
          ? 'approved'
          : (renterVerificationStatusRaw ?? 'pending'))
        : (ownerVerificationApproved
          ? 'approved'
          : (ownerVerificationStatus ?? ownerDetailsStatus ?? propertyVerificationStatus ?? 'pending'));

      final effectiveIdType = isRenter
        ? (renterVerification?['id_type'] as String?)
        : (ownerVerification?['id_type'] as String?);
      final effectiveIdNumberMasked = isRenter
        ? ((renterVerification?['id_number_masked'] as String?) ??
          (renterVerification?['id_number'] as String?))
        : ((ownerVerification?['id_number_masked'] as String?) ??
          (ownerVerification?['id_number'] as String?));
      final effectiveIdDocumentUrl = isRenter
        ? (renterVerification?['document_url'] as String?)
        : ((ownerVerification?['document_url'] as String?) ??
          (verification?['ownership_document_url'] as String?) ??
          (verification?['document_url'] as String?));

    return ProfessionalDetailsState(
      ownerType: (ownerDetails?['owner_type'] as String?) ??
        (professional?['owner_type'] as String?) ??
        (profile?['owner_type'] as String?) ??
        'Individual',
      renterType: (profile?['renter_type'] as String?) ?? 'student',
      yearsOfExperience: professional?['years_of_experience'] as int? ??
        profile?['years_of_experience'] as int?,
      city: professional?['city'] as String? ?? profile?['city'] as String?,
      emergencyContact:
        professional?['emergency_contact'] as String? ?? profile?['emergency_contact'] as String?,
        idType: effectiveIdType,
        idNumberMasked: effectiveIdNumberMasked,
        idDocumentUrl: effectiveIdDocumentUrl,
      companyName: companyOwners?['company_name'] as String?,
      gstNumber: companyOwners?['gst_number'] as String?,
      cinNumber: companyOwners?['cin_number'] as String?,
      authorizedPersonName: companyOwners?['authorized_person_name'] as String?,
      authorizedPersonPan: companyOwners?['authorized_person_pan'] as String?,
      brokerAgencyName: brokerOwners?['agency_name'] as String?,
      brokerReraNumber: brokerOwners?['rera_number'] as String?,
      brokerLicenseNumber: brokerOwners?['license_number'] as String?,
      landlordBusinessName: professionalLandlords?['business_name'] as String?,
      landlordTotalPropertiesOwned: professionalLandlords?['total_properties_owned'] as int?,
      landlordPanNumber: professionalLandlords?['pan_number'] as String?,
      individualOccupation: individualOwners?['occupation'] as String?,
      individualAddress: individualOwners?['address'] as String?,
      individualPanNumber: individualOwners?['pan_number'] as String?,
      individualAadhaarLast4: individualOwners?['aadhaar_last4'] as String?,
      studentCollegeName: renterStudent?['college_name'] as String?,
      studentCourseYear: renterStudent?['course_year'] as String?,
      studentCollegeId: renterStudent?['college_id'] as String?,
      studentGuardianName: renterStudent?['guardian_name'] as String?,
      studentGuardianPhone: renterStudent?['guardian_phone'] as String?,
      workingCompanyName: renterWorking?['company_name'] as String?,
      workingJobTitle: renterWorking?['job_title'] as String?,
      workingOfficeAddress: renterWorking?['office_address'] as String?,
      workingWorkEmail: renterWorking?['work_email'] as String?,
      selfEmployedBusinessName: renterSelfEmployed?['business_name'] as String?,
      selfEmployedNatureOfWork: renterSelfEmployed?['nature_of_work'] as String?,
      selfEmployedOfficeAddress: renterSelfEmployed?['office_address'] as String?,
      propertyId: propertyId,
      verificationStatus: resolvedVerificationStatus,
      emergencyContactVerified: profile?['emergency_contact_verified'] == true,
    );
  }

  Future<void> _upsertOwnerDetails(Map<String, dynamic> values) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('owner_details').upsert({
      'owner_id': user.id,
      ...values,
    }, onConflict: 'owner_id');
  }

  Future<void> _upsertCompanyOwners(Map<String, dynamic> values) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('company_owners').upsert({
      'owner_id': user.id,
      ...values,
    }, onConflict: 'owner_id');
  }

  Future<void> _upsertBrokerOwners(Map<String, dynamic> values) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('broker_owners').upsert({
      'owner_id': user.id,
      ...values,
    }, onConflict: 'owner_id');
  }

  Future<void> _upsertProfessionalLandlords(Map<String, dynamic> values) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('professional_landlords').upsert({
      'owner_id': user.id,
      ...values,
    }, onConflict: 'owner_id');
  }

  Future<void> _upsertIndividualOwners(Map<String, dynamic> values) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('individual_owners').upsert({
      'owner_id': user.id,
      ...values,
    }, onConflict: 'owner_id');
  }

  Future<void> _upsertRenterStudents(Map<String, dynamic> values) async {
    final user = _client.auth.currentUser;
    if (user == null || _renterStudentTableMissing) return;

    try {
      await _client.from('renter_students').upsert({
        'renter_id': user.id,
        ...values,
      }, onConflict: 'renter_id');
    } on PostgrestException catch (error) {
      if (_isMissingTableOrColumnError(error)) {
        _renterStudentTableMissing = true;
        return;
      }
      rethrow;
    }
  }

  Future<void> _upsertRenterWorkingProfessionals(Map<String, dynamic> values) async {
    final user = _client.auth.currentUser;
    if (user == null || _renterWorkingTableMissing) return;

    try {
      await _client.from('renter_working_professionals').upsert({
        'renter_id': user.id,
        ...values,
      }, onConflict: 'renter_id');
    } on PostgrestException catch (error) {
      if (_isMissingTableOrColumnError(error)) {
        _renterWorkingTableMissing = true;
        return;
      }
      rethrow;
    }
  }

  Future<void> _upsertRenterSelfEmployed(Map<String, dynamic> values) async {
    final user = _client.auth.currentUser;
    if (user == null || _renterSelfEmployedTableMissing) return;

    try {
      await _client.from('renter_self_employed').upsert({
        'renter_id': user.id,
        ...values,
      }, onConflict: 'renter_id');
    } on PostgrestException catch (error) {
      if (_isMissingTableOrColumnError(error)) {
        _renterSelfEmployedTableMissing = true;
        return;
      }
      rethrow;
    }
  }

  Future<bool> _isCurrentUserRenter() async {
    final user = _client.auth.currentUser;
    if (user == null) return false;

    try {
      final profile = await _client
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();
      final role = (profile?['role'] as String?)?.trim().toLowerCase() ?? '';
      return role == 'renter';
    } catch (_) {
      return false;
    }
  }

  Future<void> _upsertProfessional(Map<String, dynamic> values) async {
    final user = _client.auth.currentUser;
    if (user == null) return;
    if (_ownerProfessionalTableMissing) return;

    final propertyId = await _getOwnerPropertyId(user.id);
    try {
      await _client.from('owner_professional_details').upsert({
        'owner_id': user.id,
        'property_id': propertyId,
        ...values,
      }, onConflict: 'owner_id');
    } on PostgrestException catch (error) {
      if ((error.code ?? '').toUpperCase() == 'PGRST205') {
        _ownerProfessionalTableMissing = true;
        return;
      }
      rethrow;
    }
  }

  Future<void> _updateProfilesFields(Map<String, dynamic> values) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final existingProfile = await _client
          .from('profiles')
          .select('email, role')
          .eq('id', user.id)
          .maybeSingle();

      final existingEmail = (existingProfile?['email'] as String?)?.trim();
      final existingRole = (existingProfile?['role'] as String?)?.trim();
      final userEmail = user.email?.trim();
      final safeEmail = (existingEmail != null && existingEmail.isNotEmpty)
          ? existingEmail
          : (userEmail ?? '');
      final safeRole = (existingRole != null && existingRole.isNotEmpty)
          ? existingRole
          : 'owner';

      await _client.from('profiles').upsert({
        'id': user.id,
        'email': safeEmail,
        'role': safeRole,
        ...values,
      }, onConflict: 'id');
    } on PostgrestException catch (error) {
      if (_isMissingTableOrColumnError(error)) return;
      rethrow;
    }
  }

  Future<void> updateOwnerType(String ownerType) async {
    final normalizedOwnerType = _normalizeOwnerTypeForStorage(ownerType);
    await _upsertOwnerDetails({
      'owner_type': normalizedOwnerType,
      'verification_status': 'pending',
    });
  }

  Future<void> updateRenterType(String renterType) async {
    final normalized = _normalizeRenterTypeForStorage(renterType);
    await _updateProfilesFields({'renter_type': normalized});
  }

  String _normalizeRenterTypeForStorage(String renterType) {
    final normalized = renterType.trim().toLowerCase();
    if (normalized == 'student') return 'student';
    if (normalized == 'working professional' || normalized == 'working_professional') {
      return 'working_professional';
    }
    if (normalized == 'self-employed' || normalized == 'self employed' || normalized == 'self_employed') {
      return 'self_employed';
    }
    return 'student';
  }

  String _normalizeOwnerTypeForStorage(String ownerType) {
    final normalized = ownerType.trim().toLowerCase();

    if (normalized == 'individual owner' || normalized == 'individual') {
      return 'individual';
    }

    if (normalized == 'broker') {
      return 'broker';
    }

    if (normalized == 'professional landlord' || normalized == 'professional_landlord') {
      return 'professional_landlord';
    }

    if (normalized == 'company / developer' || normalized == 'company') {
      return 'company';
    }

    return 'individual';
  }

  Future<void> updateYearsOfExperience(int years) async {
    await _upsertProfessional({'years_of_experience': years});
    await _updateProfilesFields({'years_of_experience': years});
  }

  Future<void> updateCity(String city) async {
    await _upsertProfessional({'city': city});
    await _updateProfilesFields({'city': city});
  }

  Future<void> updateEmergencyContact(String contact) async {
    await _upsertProfessional({'emergency_contact': contact});
    await _updateProfilesFields({
      'emergency_contact': contact,
      'emergency_contact_verified': false,
    });
  }

  Future<void> updateEmergencyContactVerified(bool verified) async {
    await _updateProfilesFields({'emergency_contact_verified': verified});
  }

  Future<void> updateGovernmentIdType(String idType) async {
    final isRenter = await _isCurrentUserRenter();
    if (isRenter) {
      await _upsertRenterVerification({'id_type': idType});
      return;
    }
    await _upsertOwnerVerification({'id_type': idType});
  }

  Future<void> updateGovernmentIdNumberMasked(String rawNumber) async {
    final trimmed = rawNumber.trim();
    if (trimmed.length < 4) return;
    final masked = '${'*' * (trimmed.length - 4)}${trimmed.substring(trimmed.length - 4)}';
    final isRenter = await _isCurrentUserRenter();
    if (isRenter) {
      await _upsertRenterVerification({'id_number_masked': masked});
      return;
    }
    await _upsertOwnerVerification({'id_number_masked': masked});
  }

  Future<void> updateGovernmentIdDocumentUrl(String documentUrl) async {
    final url = documentUrl.trim();
    if (url.isEmpty) return;
    final isRenter = await _isCurrentUserRenter();
    if (isRenter) {
      await _upsertRenterVerification({'document_url': url});
      return;
    }
    await _upsertOwnerVerification({'document_url': url});
  }

  Future<void> updateCompanyName(String companyName) async {
    final trimmed = companyName.trim();
    if (trimmed.isEmpty) return;
    await _upsertCompanyOwners({'company_name': trimmed});
  }

  Future<void> updateGstNumber(String gstNumber) async {
    final trimmed = gstNumber.trim();
    if (trimmed.isEmpty) return;
    await _upsertCompanyOwners({'gst_number': trimmed});
  }

  Future<void> updateCinNumber(String cinNumber) async {
    final trimmed = cinNumber.trim();
    if (trimmed.isEmpty) return;
    await _upsertCompanyOwners({'cin_number': trimmed});
  }

  Future<void> updateAuthorizedPersonName(String authorizedPersonName) async {
    final trimmed = authorizedPersonName.trim();
    if (trimmed.isEmpty) return;
    await _upsertCompanyOwners({'authorized_person_name': trimmed});
  }

  Future<void> updateAuthorizedPersonPan(String authorizedPersonPan) async {
    final trimmed = authorizedPersonPan.trim();
    if (trimmed.isEmpty) return;
    await _upsertCompanyOwners({'authorized_person_pan': trimmed.toUpperCase()});
  }

  Future<void> updateBrokerAgencyName(String agencyName) async {
    final trimmed = agencyName.trim();
    if (trimmed.isEmpty) return;
    await _upsertBrokerOwners({'agency_name': trimmed});
  }

  Future<void> updateBrokerReraNumber(String reraNumber) async {
    final trimmed = reraNumber.trim();
    if (trimmed.isEmpty) return;
    await _upsertBrokerOwners({'rera_number': trimmed.toUpperCase()});
  }

  Future<void> updateBrokerLicenseNumber(String licenseNumber) async {
    final trimmed = licenseNumber.trim();
    if (trimmed.isEmpty) return;
    await _upsertBrokerOwners({'license_number': trimmed.toUpperCase()});
  }

  Future<void> updateLandlordBusinessName(String businessName) async {
    final trimmed = businessName.trim();
    if (trimmed.isEmpty) return;
    await _upsertProfessionalLandlords({'business_name': trimmed});
  }

  Future<void> updateLandlordTotalPropertiesOwned(String countText) async {
    final count = int.tryParse(countText.trim());
    if (count == null || count < 0) return;
    await _upsertProfessionalLandlords({'total_properties_owned': count});
  }

  Future<void> updateLandlordPanNumber(String panNumber) async {
    final trimmed = panNumber.trim();
    if (trimmed.isEmpty) return;
    await _upsertProfessionalLandlords({'pan_number': trimmed.toUpperCase()});
  }

  Future<void> updateIndividualOccupation(String occupation) async {
    final trimmed = occupation.trim();
    if (trimmed.isEmpty) return;
    await _upsertIndividualOwners({'occupation': trimmed});
  }

  Future<void> updateIndividualAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) return;
    await _upsertIndividualOwners({'address': trimmed});
  }

  Future<void> updateIndividualPanNumber(String panNumber) async {
    final trimmed = panNumber.trim();
    if (trimmed.isEmpty) return;
    await _upsertIndividualOwners({'pan_number': trimmed.toUpperCase()});
  }

  Future<void> updateIndividualAadhaarLast4(String aadhaarLast4) async {
    final trimmed = aadhaarLast4.trim();
    if (trimmed.isEmpty) return;
    await _upsertIndividualOwners({'aadhaar_last4': trimmed});
  }

  Future<void> updateStudentCollegeName(String collegeName) async {
    final trimmed = collegeName.trim();
    if (trimmed.isEmpty) return;
    await _upsertRenterStudents({'college_name': trimmed});
  }

  Future<void> updateStudentCourseYear(String courseYear) async {
    final trimmed = courseYear.trim();
    if (trimmed.isEmpty) return;
    await _upsertRenterStudents({'course_year': trimmed});
  }

  Future<void> updateStudentCollegeId(String collegeId) async {
    final trimmed = collegeId.trim();
    if (trimmed.isEmpty) return;
    await _upsertRenterStudents({'college_id': trimmed});
  }

  Future<void> updateStudentGuardianName(String guardianName) async {
    final trimmed = guardianName.trim();
    if (trimmed.isEmpty) return;
    await _upsertRenterStudents({'guardian_name': trimmed});
  }

  Future<void> updateStudentGuardianPhone(String guardianPhone) async {
    final trimmed = guardianPhone.trim();
    if (trimmed.isEmpty) return;
    await _upsertRenterStudents({'guardian_phone': trimmed});
  }

  Future<void> updateWorkingCompanyName(String companyName) async {
    final trimmed = companyName.trim();
    if (trimmed.isEmpty) return;
    await _upsertRenterWorkingProfessionals({'company_name': trimmed});
  }

  Future<void> updateWorkingJobTitle(String jobTitle) async {
    final trimmed = jobTitle.trim();
    if (trimmed.isEmpty) return;
    await _upsertRenterWorkingProfessionals({'job_title': trimmed});
  }

  Future<void> updateWorkingOfficeAddress(String officeAddress) async {
    final trimmed = officeAddress.trim();
    if (trimmed.isEmpty) return;
    await _upsertRenterWorkingProfessionals({'office_address': trimmed});
  }

  Future<void> updateWorkingWorkEmail(String workEmail) async {
    final trimmed = workEmail.trim();
    if (trimmed.isEmpty) return;
    await _upsertRenterWorkingProfessionals({'work_email': trimmed});
  }

  Future<void> updateSelfEmployedBusinessName(String businessName) async {
    final trimmed = businessName.trim();
    if (trimmed.isEmpty) return;
    await _upsertRenterSelfEmployed({'business_name': trimmed});
  }

  Future<void> updateSelfEmployedNatureOfWork(String natureOfWork) async {
    final trimmed = natureOfWork.trim();
    if (trimmed.isEmpty) return;
    await _upsertRenterSelfEmployed({'nature_of_work': trimmed});
  }

  Future<void> updateSelfEmployedOfficeAddress(String officeAddress) async {
    final trimmed = officeAddress.trim();
    if (trimmed.isEmpty) return;
    await _upsertRenterSelfEmployed({'office_address': trimmed});
  }

  Future<void> _upsertOwnerVerification(Map<String, dynamic> values) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      await _client.from('owner_verifications').upsert({
        'owner_id': user.id,
        ...values,
      }, onConflict: 'owner_id');
      return;
    } on PostgrestException catch (error) {
      final message = (error.message).toLowerCase();
      final code = (error.code ?? '').toUpperCase();

      // Backward-compat: some DBs use id_number instead of id_number_masked.
      if (code == 'PGRST204' &&
          values.containsKey('id_number_masked') &&
          message.contains('id_number_masked')) {
        final fallback = Map<String, dynamic>.from(values);
        fallback['id_number'] = fallback.remove('id_number_masked');
        await _client.from('owner_verifications').upsert({
          'owner_id': user.id,
          ...fallback,
        }, onConflict: 'owner_id');
        return;
      }

      rethrow;
    }
  }

  Future<void> _upsertRenterVerification(Map<String, dynamic> values) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final payload = <String, dynamic>{
      'renter_id': user.id,
      ...values,
    };

    if (values.containsKey('id_type') ||
        values.containsKey('id_number_masked') ||
        values.containsKey('document_url')) {
      payload['verification_status'] = 'pending';
    }

    try {
      await _client.from('renter_verifications').upsert(
        payload,
        onConflict: 'renter_id',
      );
      return;
    } on PostgrestException catch (error) {
      final message = (error.message).toLowerCase();
      final code = (error.code ?? '').toUpperCase();

      if (code == 'PGRST204' &&
          values.containsKey('id_number_masked') &&
          message.contains('id_number_masked')) {
        final fallback = Map<String, dynamic>.from(payload);
        fallback['id_number'] = fallback.remove('id_number_masked');
        await _client.from('renter_verifications').upsert(
          fallback,
          onConflict: 'renter_id',
        );
        return;
      }

      rethrow;
    }
  }

  Future<void> upsertPropertyVerification({
    required String documentType,
    required String documentUrl,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    final propertyId = await _getOwnerPropertyId(user.id);
    if (propertyId == null) return;

    await _client.from('property_verifications').insert({
      'property_id': propertyId,
      'ownership_document_url': documentUrl,
      'utility_bill_url': documentUrl,
      'verification_status': 'pending',
      'document_type': documentType,
      'document_url': documentUrl,
      'status': 'pending',
    });
  }
}

final professionalDetailsControllerProvider = Provider<ProfessionalDetailsController>((ref) {
  return ProfessionalDetailsController();
});

final professionalDetailsProvider = FutureProvider<ProfessionalDetailsState>((ref) async {
  return ref.read(professionalDetailsControllerProvider).fetch();
});

/// ProfileData holds all fields from the profiles table
class ProfileData {
  const ProfileData({
    required this.userId,
    required this.email,
    required this.phoneVerified,
    this.role,
    this.fullName,
    this.phone,
    this.city,
    this.budget,
    this.propertyType,
    this.relativesEmails = const <String>[],
  });

  final String userId;
  final String email;
  final bool phoneVerified;
  final String? role;
  final String? fullName;
  final String? phone;
  final String? city;
  final String? budget;
  final String? propertyType;
  final List<String> relativesEmails;

  ProfileData copyWith({
    String? userId,
    String? email,
    bool? phoneVerified,
    String? role,
    String? fullName,
    String? phone,
    String? city,
    String? budget,
    String? propertyType,
    List<String>? relativesEmails,
  }) {
    return ProfileData(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      role: role ?? this.role,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      city: city ?? this.city,
      budget: budget ?? this.budget,
      propertyType: propertyType ?? this.propertyType,
      relativesEmails: relativesEmails ?? this.relativesEmails,
    );
  }
}

class ProfileDataController {
  final _client = SupabaseService.client;

  Future<ProfileData> fetch() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const ProfileData(userId: '', email: '', phoneVerified: false);
    }

    Map<String, dynamic>? profile;
    try {
      profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
    } catch (_) {
      profile = null;
    }

    final relativesList = _parseRelativesEmails(profile?['relatives_emails']);

    return ProfileData(
      userId: user.id,
      email: profile?['email'] as String? ?? user.email ?? '',
      phoneVerified: profile?['phone_verified'] as bool? ?? (user.phoneConfirmedAt != null),
      role: profile?['role'] as String?,
      fullName: profile?['full_name'] as String?,
      phone: profile?['phone'] as String?,
      city: profile?['city'] as String?,
      budget: profile?['budget'] as String?,
      propertyType: profile?['property_type'] as String?,
      relativesEmails: relativesList,
    );
  }

  Future<void> updateField(String fieldName, Object? value) async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _client.from('profiles').update({
      fieldName: value,
    }).eq('id', user.id);
  }

  Future<void> updateFullName(String fullName) async {
    final trimmed = fullName.trim();
    if (trimmed.isNotEmpty) {
      await updateField('full_name', trimmed);
    }
  }

  Future<void> updatePhone(String phone) async {
    final trimmed = phone.trim();
    if (trimmed.isNotEmpty) {
      await updateField('phone', trimmed);
    }
  }

  Future<void> updateCity(String city) async {
    final trimmed = city.trim();
    if (trimmed.isNotEmpty) {
      await updateField('city', trimmed);
    }
  }

  Future<void> updateBudget(String budget) async {
    final trimmed = budget.trim();
    if (trimmed.isNotEmpty) {
      await updateField('budget', trimmed);
    }
  }

  Future<void> updatePropertyType(String propertyType) async {
    final trimmed = propertyType.trim();
    if (trimmed.isNotEmpty) {
      await updateField('property_type', trimmed);
    }
  }

  Future<void> updateRole(String role) async {
    final trimmed = role.trim();
    if (trimmed.isNotEmpty) {
      await updateField('role', trimmed);
    }
  }

  Future<void> updateRelativesEmails(List<String> emails) async {
    await updateField('relatives_emails', emails);
  }
}

List<String> _parseRelativesEmails(dynamic raw) {
  if (raw == null) return const <String>[];
  if (raw is List) {
    return raw
        .whereType<String>()
        .map((email) => email.trim())
        .where((email) => email.isNotEmpty)
        .toList(growable: false);
  }
  if (raw is String) {
    return raw
        .split(',')
        .map((email) => email.trim())
        .where((email) => email.isNotEmpty)
        .toList(growable: false);
  }
  return const <String>[];
}

final profileDataControllerProvider = Provider<ProfileDataController>((ref) {
  return ProfileDataController();
});

final profileDataProvider = FutureProvider<ProfileData>((ref) async {
  return ref.read(profileDataControllerProvider).fetch();
});