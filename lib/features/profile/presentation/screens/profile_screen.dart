import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/routes.dart';
import '../../../auth/auth_controller.dart';
import '../../../auth/providers/user_role_provider.dart';
import '../../../../providers/theme_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/profile_option_tile.dart';
import '../../../sos/services/relatives_alert_service.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileUiStateProvider);
    final profileDataAsync = ref.watch(profileDataProvider);
    final profileData = profileDataAsync.valueOrNull;
    final userRoleAsync = ref.watch(userRoleProvider);
    final resolvedRole =
      (userRoleAsync.valueOrNull ?? profileData?.role ?? '').trim().toLowerCase();
    final isRenter = resolvedRole == 'renter';
    final professionalAsync = ref.watch(professionalDetailsProvider);
    final professional = professionalAsync.valueOrNull;
    final currentUser = Supabase.instance.client.auth.currentUser;
    final phoneNumber = (currentUser?.phone ?? '').trim();
    final isEmailVerified = currentUser?.emailConfirmedAt != null;
    final isPhoneVerified = profileData?.phoneVerified ?? (currentUser?.phoneConfirmedAt != null);
    final relativesEmails = profileData?.relativesEmails ?? const <String>[];
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return DefaultTabController(
      length: 4,
      initialIndex: initialTab.clamp(0, 3),
      child: Column(
        children: [
          // Profile Header Card
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.transparent,
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: const Color(0xFFE9ECEF),
                  child: ClipOval(
                    child: profile.imageUrl.isEmpty
                        ? const Icon(Icons.person_outline, size: 30)
                        : SizedBox.expand(
                            child: Image.network(
                              profile.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.person_outline, size: 30);
                              },
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  profile.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _showEditProfileDialog(context, ref, profile.name),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // TAB BAR
          TabBar(
            indicatorColor: Colors.deepPurple,
            labelColor: Colors.deepPurple,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'Personal'),
              Tab(icon: Icon(Icons.work), text: 'Professional'),
              Tab(icon: Icon(Icons.family_restroom), text: 'Relatives'),
              Tab(icon: Icon(Icons.settings), text: 'Settings'),
            ],
          ),

          // TAB CONTENT
          Expanded(
            child: TabBarView(
              children: [
                // PERSONAL TAB
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSectionHeader(context, 'Personal Details'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildDetailTile(
                              context,
                              'Display Name',
                              profile.name,
                              Icons.person,
                              onTap: () => _showEditProfileDialog(context, ref, profile.name),
                            ),
                            const Divider(),
                            _buildDetailTile(
                              context,
                              'Email',
                              profileData?.email ?? profile.email,
                              Icons.email,
                              isVerified: isEmailVerified,
                              showVerificationStatus: true,
                              onTap: () => _showEditEmailDialog(context, ref, profileData?.email ?? ''),
                            ),
                            if (!isEmailVerified) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showEmailVerificationDialog(context, ref),
                                  icon: const Icon(Icons.mail_outline, size: 18),
                                  label: const Text('Send Verification Email'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade400,
                                  ),
                                ),
                              ),
                            ],
                            const Divider(),
                            _buildDetailTile(
                              context,
                              'Phone Number',
                              profileData?.phone ?? phoneNumber,
                              Icons.phone,
                              isVerified: isPhoneVerified,
                              showVerificationStatus: true,
                              onTap: () => _showPhoneEditDialog(context, ref, profileData?.phone ?? phoneNumber),
                            ),
                            if (!isPhoneVerified) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showPhoneVerificationDialog(context, ref),
                                  icon: const Icon(Icons.verified_user, size: 18),
                                  label: const Text('Send OTP & Verify'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade400,
                                  ),
                                ),
                              ),
                            ],
                            const Divider(),
                            _buildDetailTile(
                              context,
                              'Role',
                              _roleLabel(profileData?.role ?? 'Not specified'),
                              Icons.badge,
                              onTap: () => _showEditRoleDialog(context, ref, profileData?.role ?? ''),
                            ),
                            if (isRenter) ...[
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Budget',
                                profileData?.budget ?? 'Not added',
                                Icons.attach_money,
                                onTap: () => _showEditBudgetDialog(context, ref, profileData?.budget ?? ''),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // PROFESSIONAL TAB
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSectionHeader(context, 'Professional Details'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildDetailTile(
                              context,
                              isRenter ? 'User Type' : 'Owner Type',
                              isRenter
                                  ? _renterTypeLabel(professional?.renterType)
                                  : _ownerTypeLabel(professional?.ownerType),
                              Icons.person_outline,
                              onTap: () => isRenter
                                  ? _showRenterTypeDialog(context, ref)
                                  : _showOwnerTypeDialog(context, ref),
                            ),
                            if (isRenter &&
                                _renterTypeLabel(professional?.renterType) == 'Student') ...[
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'College Name',
                                professional?.studentCollegeName ?? 'Not added',
                                Icons.school,
                                onTap: () => _showStudentCollegeNameDialog(context, ref),
                              ),
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Course / Year',
                                professional?.studentCourseYear ?? 'Not added',
                                Icons.menu_book,
                                onTap: () => _showStudentCourseYearDialog(context, ref),
                              ),
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'College ID',
                                professional?.studentCollegeId ?? 'Not added',
                                Icons.badge,
                                onTap: () => _showStudentCollegeIdDialog(context, ref),
                              ),
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Guardian Name',
                                professional?.studentGuardianName ?? 'Not added',
                                Icons.person,
                                onTap: () => _showStudentGuardianNameDialog(context, ref),
                              ),
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Guardian Phone',
                                professional?.studentGuardianPhone ?? 'Not added',
                                Icons.phone,
                                onTap: () => _showStudentGuardianPhoneDialog(context, ref),
                              ),
                            ],
                            if (isRenter &&
                                _renterTypeLabel(professional?.renterType) == 'Working Professional') ...[
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Company Name',
                                professional?.workingCompanyName ?? 'Not added',
                                Icons.business,
                                onTap: () => _showWorkingCompanyNameDialog(context, ref),
                              ),
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Job Title',
                                professional?.workingJobTitle ?? 'Not added',
                                Icons.work,
                                onTap: () => _showWorkingJobTitleDialog(context, ref),
                              ),
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Office Address',
                                professional?.workingOfficeAddress ?? 'Not added',
                                Icons.location_city,
                                onTap: () => _showWorkingOfficeAddressDialog(context, ref),
                              ),
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Work Email',
                                professional?.workingWorkEmail ?? 'Not added',
                                Icons.email,
                                onTap: () => _showWorkingWorkEmailDialog(context, ref),
                              ),
                            ],
                            if (isRenter &&
                                _renterTypeLabel(professional?.renterType) == 'Self-Employed') ...[
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Business Name',
                                professional?.selfEmployedBusinessName ?? 'Not added',
                                Icons.storefront,
                                onTap: () => _showSelfEmployedBusinessNameDialog(context, ref),
                              ),
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Nature of Work',
                                professional?.selfEmployedNatureOfWork ?? 'Not added',
                                Icons.handyman,
                                onTap: () => _showSelfEmployedNatureOfWorkDialog(context, ref),
                              ),
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Office Address',
                                professional?.selfEmployedOfficeAddress ?? 'Not added',
                                Icons.location_on,
                                onTap: () => _showSelfEmployedOfficeAddressDialog(context, ref),
                              ),
                            ],
                            if (!isRenter &&
                              _ownerTypeLabel(professional?.ownerType) == 'Company') ...[
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Company Name',
                                professional?.companyName ?? 'Not added',
                                Icons.business,
                                onTap: () => _showCompanyNameDialog(context, ref),
                              ),
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Authorized Person Name',
                                professional?.authorizedPersonName ?? 'Not added',
                                Icons.person_pin,
                                onTap: () => _showAuthorizedPersonNameDialog(context, ref),
                              ),
                            ],
                            if (!isRenter &&
                              _ownerTypeLabel(professional?.ownerType) == 'Broker') ...[
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Agency Name',
                                professional?.brokerAgencyName ?? 'Not added',
                                Icons.apartment,
                                onTap: () => _showBrokerAgencyNameDialog(context, ref),
                              ),
                            ],
                            if (!isRenter &&
                              _ownerTypeLabel(professional?.ownerType) == 'Professional Landlord') ...[
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Business Name',
                                professional?.landlordBusinessName ?? 'Not added',
                                Icons.business_center,
                                onTap: () => _showLandlordBusinessNameDialog(context, ref),
                              ),
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Total Properties Owned',
                                professional?.landlordTotalPropertiesOwned?.toString() ?? 'Not added',
                                Icons.home_work,
                                onTap: () => _showLandlordTotalPropertiesDialog(context, ref),
                              ),
                            ],
                            if (!isRenter &&
                              _ownerTypeLabel(professional?.ownerType) == 'Individual') ...[
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Occupation',
                                professional?.individualOccupation ?? 'Not added',
                                Icons.work_outline,
                                onTap: () => _showIndividualOccupationDialog(context, ref),
                              ),
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Address',
                                professional?.individualAddress ?? 'Not added',
                                Icons.home_outlined,
                                onTap: () => _showIndividualAddressDialog(context, ref),
                              ),
                            ],
                              if (!isRenter) ...[
                                const Divider(),
                                _buildDetailTile(
                                  context,
                                  'Years of Experience',
                                  professional?.yearsOfExperience == null
                                      ? 'Not added'
                                      : '${professional!.yearsOfExperience} years',
                                  Icons.timeline,
                                  onTap: () => _showYearsOfExperienceDialog(context, ref),
                                ),
                              ],
                            const Divider(),
                            _buildDetailTile(
                              context,
                              'City',
                              professional?.city ?? 'Not specified',
                              Icons.location_city,
                              onTap: () => _showCityDialog(context, ref),
                            ),
                            const Divider(),
                            _buildDetailTile(
                              context,
                              'Emergency Contact',
                              professional?.emergencyContact ?? 'Not added',
                              Icons.phone_in_talk,
                              isVerified: professional?.emergencyContactVerified ?? false,
                              showVerificationStatus: true,
                              onTap: () => _showEmergencyContactDialog(context, ref),
                            ),
                            if ((professional?.emergencyContact ?? '').isNotEmpty &&
                                !(professional?.emergencyContactVerified ?? false)) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showEmergencyVerificationDialog(context, ref),
                                  icon: const Icon(Icons.sms_outlined, size: 18),
                                  label: const Text('Send OTP & Verify Emergency Number'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, 'Government ID'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildDetailTile(
                              context,
                              'ID Type',
                              professional?.idType ?? 'Not selected',
                              Icons.credit_card,
                              onTap: () => _showIDTypeDialog(context, ref),
                            ),
                            const Divider(),
                            _buildDetailTile(
                              context,
                              'ID Number',
                              professional?.idNumberMasked ?? 'Not added',
                              Icons.numbers,
                              onTap: () => _showIDNumberDialog(context, ref),
                            ),
                            const Divider(),
                            _buildDetailTile(
                              context,
                              'ID Document',
                              professional?.idDocumentUrl == null ? 'Not uploaded' : 'Uploaded',
                              Icons.file_present,
                              onTap: () => _showIDUploadDialog(context, ref),
                            ),
                            if (!isRenter &&
                              _ownerTypeLabel(professional?.ownerType) == 'Company') ...[
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'GST Number',
                                professional?.gstNumber ?? 'Not added',
                                Icons.receipt_long,
                                onTap: () => _showGstNumberDialog(context, ref),
                              ),
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'CIN Number',
                                professional?.cinNumber ?? 'Not added',
                                Icons.badge,
                                onTap: () => _showCinNumberDialog(context, ref),
                              ),
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Authorized Person PAN',
                                professional?.authorizedPersonPan ?? 'Not added',
                                Icons.credit_card,
                                onTap: () => _showAuthorizedPersonPanDialog(context, ref),
                              ),
                            ],
                            if (!isRenter &&
                              _ownerTypeLabel(professional?.ownerType) == 'Broker') ...[
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'RERA Number',
                                professional?.brokerReraNumber ?? 'Not added',
                                Icons.verified,
                                onTap: () => _showBrokerReraNumberDialog(context, ref),
                              ),
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Broker License Number',
                                professional?.brokerLicenseNumber ?? 'Not added',
                                Icons.assignment_turned_in,
                                onTap: () => _showBrokerLicenseNumberDialog(context, ref),
                              ),
                            ],
                            if (!isRenter &&
                              _ownerTypeLabel(professional?.ownerType) == 'Professional Landlord') ...[
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Landlord PAN',
                                professional?.landlordPanNumber ?? 'Not added',
                                Icons.badge,
                                onTap: () => _showLandlordPanNumberDialog(context, ref),
                              ),
                            ],
                            if (!isRenter &&
                              _ownerTypeLabel(professional?.ownerType) == 'Individual') ...[
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Individual PAN',
                                professional?.individualPanNumber ?? 'Not added',
                                Icons.badge_outlined,
                                onTap: () => _showIndividualPanNumberDialog(context, ref),
                              ),
                              const Divider(),
                              _buildDetailTile(
                                context,
                                'Aadhaar Last 4 Digits',
                                professional?.individualAadhaarLast4 ?? 'Not added',
                                Icons.pin,
                                onTap: () => _showIndividualAadhaarLast4Dialog(context, ref),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionHeader(context, 'Status'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildDetailTile(
                              context,
                              'Verification Status',
                              (professional?.verificationStatus ?? 'pending').toUpperCase(),
                              Icons.verified_user,
                              isVerified: (professional?.verificationStatus ?? 'pending')
                                  .trim()
                                  .toLowerCase() ==
                                  'approved',
                              onTap: () => _showVerificationInfoDialog(context),
                            ),
                            const Divider(),
                            _buildDetailTile(
                              context,
                              'Trust Score',
                              '0/100',
                              Icons.star,
                              onTap: () => _showTrustScoreDialog(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // RELATIVES TAB
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSectionHeader(context, 'Relatives'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Add up to 5 relatives who can receive emergency alerts.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            if (relativesEmails.isEmpty)
                              Text(
                                'No relatives added yet.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey.shade700,
                                    ),
                              ),
                            for (var i = 0; i < relativesEmails.length; i++) ...[
                              _buildRelativeEmailTile(
                                context,
                                relativesEmails[i],
                                onRemove: () => _removeRelativeEmail(
                                  context,
                                  ref,
                                  relativesEmails[i],
                                  relativesEmails,
                                ),
                              ),
                              if (i != relativesEmails.length - 1) const Divider(),
                            ],
                            if (relativesEmails.length < 5) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => _showAddRelativeDialog(
                                    context,
                                    ref,
                                    relativesEmails,
                                  ),
                                  icon: const Icon(Icons.person_add_alt_1),
                                  label: const Text('Add Relative'),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader(context, 'Alert Emails'),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Send a live-location emergency email to all saved relatives.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: relativesEmails.isEmpty
                                    ? null
                                    : () => _sendRelativesAlertFromProfile(
                                          context,
                                          ref,
                                          relativesEmails,
                                          profile.name,
                                          profileData,
                                        ),
                                icon: const Icon(Icons.mark_email_unread),
                                label: const Text('Send Alert Email'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // SETTINGS TAB
                ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSectionHeader(context, 'App Preferences'),
                    Card(
                      child: SwitchListTile(
                        title: const Text('Dark Mode'),
                        subtitle: const Text('Use dark theme across the app'),
                        value: isDarkMode,
                        onChanged: (value) {
                          ref.read(themeModeProvider.notifier).setDarkMode(value);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionHeader(context, 'Account'),
                    ProfileOptionTile(
                      title: 'Upload Profile Image',
                      icon: Icons.photo_camera_outlined,
                      onTap: () => _showImageUrlDialog(context, ref),
                    ),
                    const SizedBox(height: 12),
                    ProfileOptionTile(
                      title: 'Delete Account',
                      icon: Icons.delete_outline,
                      backgroundColor: Colors.red.shade50,
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (dialogContext) => AlertDialog(
                            title: const Text('Delete Account'),
                            content: const Text(
                              'Are you sure? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  _showMessage(context, 'Delete request submitted');
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    ProfileOptionTile(
                      title: 'Logout',
                      icon: Icons.logout,
                      backgroundColor: Colors.amber.shade50,
                      onTap: () => _handleLogout(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Colors.deepPurple,
            ),
      ),
    );
  }

  Widget _buildDetailTile(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isVerified = false,
    VoidCallback? onTap,
    bool showVerificationStatus = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.deepPurple, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 220),
                        child: Text(
                          value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      if (showVerificationStatus)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isVerified ? Colors.green.shade100 : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isVerified ? 'Verified' : 'Unverified',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: isVerified ? Colors.green.shade800 : Colors.orange.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        )
                      else if (isVerified)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Verified',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: Colors.green.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.edit, color: Colors.deepPurple, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRelativeEmailTile(
    BuildContext context,
    String email, {
    required VoidCallback onRemove,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.alternate_email, color: Colors.deepPurple),
      title: Text(email),
      trailing: IconButton(
        icon: const Icon(Icons.close, color: Colors.redAccent),
        tooltip: 'Remove',
        onPressed: onRemove,
      ),
    );
  }

  Future<void> _showAddRelativeDialog(
    BuildContext context,
    WidgetRef ref,
    List<String> currentEmails,
  ) async {
    if (currentEmails.length >= 5) {
      _showMessage(context, 'You can only add up to 5 relatives.');
      return;
    }

    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Add Relative Email'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'name@example.com'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = controller.text.trim().toLowerCase();
                if (!_isValidEmail(email)) {
                  _showMessage(context, 'Please enter a valid email address.');
                  return;
                }
                final exists = currentEmails.any(
                  (existing) => existing.toLowerCase() == email,
                );
                if (exists) {
                  _showMessage(context, 'This email is already saved.');
                  return;
                }

                final updated = [...currentEmails, email];

                try {
                  await ref
                      .read(profileDataControllerProvider)
                      .updateRelativesEmails(updated);
                  ref.invalidate(profileDataProvider);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _showMessage(context, 'Relative added.');
                } catch (e) {
                  _showMessage(context, _formatSaveError(e));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _removeRelativeEmail(
    BuildContext context,
    WidgetRef ref,
    String email,
    List<String> currentEmails,
  ) async {
    final updated = currentEmails
        .where((item) => item.toLowerCase() != email.toLowerCase())
        .toList();

    try {
      await ref.read(profileDataControllerProvider).updateRelativesEmails(updated);
      ref.invalidate(profileDataProvider);
      _showMessage(context, 'Relative removed.');
    } catch (e) {
      _showMessage(context, _formatSaveError(e));
    }
  }

  Future<void> _sendRelativesAlertFromProfile(
    BuildContext context,
    WidgetRef ref,
    List<String> relatives,
    String displayName,
    ProfileData? profileData,
  ) async {
    if (relatives.isEmpty) {
      _showMessage(context, 'Add at least one relative first.');
      return;
    }

    final emergencyNote = await _promptEmergencyDetails(context);
    if (emergencyNote == null) return;
    final resolvedNote = emergencyNote.isEmpty
      ? 'Emergency details not provided.'
      : emergencyNote;

    final position = await _getCurrentPosition(context);
    if (position == null) return;

    final currentUser = Supabase.instance.client.auth.currentUser;
    final userEmail = profileData?.email ?? currentUser?.email;
    final userPhone = profileData?.phone ?? currentUser?.phone;

    final success = await RelativesAlertService().sendAlertEmail(
      recipients: relatives,
      userId: profileData?.userId ?? currentUser?.id ?? '',
      userName: displayName,
      userEmail: userEmail,
      userPhone: userPhone,
      latitude: position.latitude,
      longitude: position.longitude,
      emergencyNote: resolvedNote,
    );

    if (!context.mounted) return;
    _showMessage(
      context,
      success
          ? 'Alert email sent to relatives.'
          : 'Unable to send alert email. Please try again later.',
    );
  }

  Future<String?> _promptEmergencyDetails(BuildContext context) async {
    final controller = TextEditingController();
    String? result;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Emergency Details'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: 'Describe the emergency (optional)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                result = controller.text.trim();
                Navigator.pop(dialogContext);
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    return result;
  }

  Future<Position?> _getCurrentPosition(BuildContext context) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage(context, 'Location services are disabled.');
      return null;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showMessage(context, 'Location permission denied.');
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      _showMessage(context, 'Unable to fetch your live location.');
      return null;
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  Future<void> _showEditProfileDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter your name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedName = controller.text.trim();
                if (updatedName.isEmpty) {
                  return;
                }

                try {
                  await ref.read(profileUiStateProvider.notifier).updateName(updatedName);
                  await ref.read(profileDataControllerProvider).updateFullName(updatedName);
                  ref.invalidate(profileDataProvider);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                } on AuthException catch (error) {
                  _showMessage(context, error.message);
                } catch (_) {
                  _showMessage(context, 'Unable to update profile name.');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEditEmailDialog(
    BuildContext context,
    WidgetRef ref,
    String currentEmail,
  ) async {
    final controller = TextEditingController(text: currentEmail);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Email'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Enter your email'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedEmail = controller.text.trim();
                if (updatedEmail.isEmpty) {
                  return;
                }

                try {
                  // Update email logic here
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    _showMessage(context, 'Email update request sent!');
                  }
                } on AuthException catch (error) {
                  _showMessage(context, error.message);
                } catch (_) {
                  _showMessage(context, 'Unable to update email.');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // EMAIL VERIFICATION DIALOG
  Future<void> _showEmailVerificationDialog(BuildContext context, WidgetRef ref) async {
    final currentEmail = Supabase.instance.client.auth.currentUser?.email ?? '';
    final isEmailVerified = Supabase.instance.client.auth.currentUser?.emailConfirmedAt != null;

    if (currentEmail.isEmpty) {
      _showMessage(context, 'Please add an email first');
      return;
    }

    if (isEmailVerified) {
      _showMessage(context, 'Email is already verified');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Verify Email Address'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Email verification link sent to:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.mail_outline, color: Colors.green.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        currentEmail,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.green.shade800,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Check your inbox for the verification link. It may take a few minutes to arrive. Don\'t forget to check your spam folder!',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Understood'),
            ),
          ],
        );
      },
    );
  }

  // PHONE NUMBER EDIT DIALOG (Just saves to profiles table, no OTP)
  Future<void> _showPhoneEditDialog(
    BuildContext context,
    WidgetRef ref,
    String currentPhone,
  ) async {
    final controller = TextEditingController(text: currentPhone);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Phone Number'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'Enter your phone number',
              prefixText: '+91 ',
              labelText: 'Phone Number',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final phone = controller.text.trim();
                if (phone.isEmpty) {
                  _showMessage(context, 'Please enter a phone number');
                  return;
                }

                try {
                  await ref.read(profileDataControllerProvider).updatePhone(phone);
                  ref.invalidate(profileDataProvider);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    _showMessage(context, 'Phone number saved');
                  }
                } catch (e) {
                  _showMessage(context, _formatSaveError(e));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showPhoneVerificationDialog(BuildContext context, WidgetRef ref) async {
    final existingPhone = Supabase.instance.client.auth.currentUser?.phone ?? '';
    final profileData = ref.read(profileDataProvider).valueOrNull;
    // Prefer phone stored in profiles table because user edits this field in UI.
    final profilePhone = (profileData?.phone ?? '').trim();
    final phoneToVerify = profilePhone.isNotEmpty ? profilePhone : existingPhone;
    final isPhoneVerified =
      profileData?.phoneVerified ?? (Supabase.instance.client.auth.currentUser?.phoneConfirmedAt != null);

    if (phoneToVerify.isEmpty) {
      _showMessage(context, 'Please add a phone number first');
      return;
    }

    // If already verified, show message
    if (isPhoneVerified) {
      _showMessage(context, 'Phone is already verified');
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Verify Phone Number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'An OTP will be sent to:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      phoneToVerify,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  final normalized = _normalizeIndianPhone(phoneToVerify);
                  if (normalized == null) {
                    _showMessage(
                      context,
                      'Invalid phone number. Enter 10-digit Indian mobile (e.g. 9876543210).',
                    );
                    return;
                  }
                  
                  // Send direct SMS OTP for phone verification.
                  await Supabase.instance.client.auth.signInWithOtp(
                    phone: normalized,
                    shouldCreateUser: false,
                    channel: OtpChannel.sms,
                  );

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _showMessage(context, 'OTP sent to $normalized');
                  
                  // Show OTP verification dialog
                  await _showOtpVerificationDialog(context, ref, normalized);
                } on AuthException catch (error) {
                  final message = error.message.toLowerCase();
                  if (message.contains('rate') || message.contains('limit')) {
                    _showMessage(context, 'Too many OTP requests. Please wait 60 seconds and try again.');
                    return;
                  }
                  if (message.contains('invalid') && message.contains('phone')) {
                    _showMessage(
                      context,
                      'Phone format rejected by server. Use 10-digit mobile number without spaces.',
                    );
                    return;
                  }
                  if (message.contains('sms') ||
                      message.contains('provider') ||
                      message.contains('twilio')) {
                    _showMessage(
                      context,
                      'SMS provider is not configured in Supabase. Configure Twilio/MessageBird first.',
                    );
                    return;
                  }
                  _showMessage(context, error.message);
                } catch (e) {
                  _showMessage(context, _formatSaveError(e));
                }
              },
              icon: const Icon(Icons.mail_outline, size: 18),
              label: const Text('Send OTP'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showOtpVerificationDialog(
    BuildContext context,
    WidgetRef ref,
    String phone,
  ) async {
    final otpController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Verify Phone Number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter OTP sent to:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 12),
              // Phone number display box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.phone, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      phone,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade800,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // OTP input field
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      letterSpacing: 8,
                      fontWeight: FontWeight.w600,
                    ),
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade300,
                        letterSpacing: 8,
                      ),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final otp = otpController.text.trim();
                if (otp.length < 4) {
                  _showMessage(context, 'Please enter valid OTP');
                  return;
                }

                try {
                  await Supabase.instance.client.auth.verifyOTP(
                    phone: phone,
                    token: otp,
                    type: OtpType.sms,
                  );

                  // Backend-controlled phone verification flag.
                  await ref
                      .read(profileDataControllerProvider)
                      .updateField('phone_verified', true);

                  ref.invalidate(profileUiStateProvider);
                  ref.invalidate(profileDataProvider);

                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _showMessage(context, 'Phone verified successfully ✓');
                } on AuthException catch (error) {
                  _showMessage(context, error.message);
                } catch (e) {
                  _showMessage(context, _formatSaveError(e));
                }
              },
              icon: const Icon(Icons.verified_user, size: 18),
              label: const Text('Verify OTP'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showVerificationInfoDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Verification Status'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your account verification is pending.'),
              SizedBox(height: 16),
              Text(
                'To get verified:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Verify your email address'),
              Text('• Verify your phone number'),
              Text('• Submit property verification documents'),
              SizedBox(height: 16),
              Text('Once verified, you will get 3x more tenant inquiries!'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Understood'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTrustScoreDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Trust Score'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your current trust score is 0/100'),
              SizedBox(height: 16),
              Text(
                'How to improve:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Complete profile verification'),
              Text('• Receive positive reviews from tenants'),
              Text('• Maintain active property listings'),
              Text('• Respond quickly to inquiries'),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _renterTypeLabel(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return 'Student';
    if (normalized == 'student') return 'Student';
    if (normalized == 'working_professional' || normalized == 'working professional') {
      return 'Working Professional';
    }
    if (normalized == 'self_employed' || normalized == 'self-employed' || normalized == 'self employed') {
      return 'Self-Employed';
    }
    return 'Student';
  }

  Future<void> _showRenterTypeDialog(BuildContext context, WidgetRef ref) async {
    final types = ['Student', 'Working Professional', 'Self-Employed'];
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    String selected = _renterTypeLabel(current?.renterType);
    if (!types.contains(selected)) {
      selected = types.first;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select User Type'),
              content: DropdownButton<String>(
                value: selected,
                isExpanded: true,
                items: types
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selected = value ?? types.first;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(professionalDetailsControllerProvider)
                          .updateRenterType(selected);
                      ref.invalidate(professionalDetailsProvider);
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _showMessage(context, 'User type updated');
                    } catch (e) {
                      _showMessage(context, _formatSaveError(e));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showStudentCollegeNameDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.studentCollegeName ?? '');
    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'College Name',
      hint: 'Enter college name',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateStudentCollegeName(value),
      successMessage: 'College name updated',
    );
  }

  Future<void> _showStudentCourseYearDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.studentCourseYear ?? '');
    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Course / Year',
      hint: 'e.g. B.Tech 3rd Year',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateStudentCourseYear(value),
      successMessage: 'Course / year updated',
    );
  }

  Future<void> _showStudentCollegeIdDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.studentCollegeId ?? '');
    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'College ID',
      hint: 'Enter college ID',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateStudentCollegeId(value),
      successMessage: 'College ID updated',
    );
  }

  Future<void> _showStudentGuardianNameDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.studentGuardianName ?? '');
    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Guardian Name',
      hint: 'Enter guardian name',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateStudentGuardianName(value),
      successMessage: 'Guardian name updated',
    );
  }

  Future<void> _showStudentGuardianPhoneDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.studentGuardianPhone ?? '');
    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Guardian Phone',
      hint: 'Enter guardian phone',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateStudentGuardianPhone(value),
      successMessage: 'Guardian phone updated',
    );
  }

  Future<void> _showWorkingCompanyNameDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.workingCompanyName ?? '');
    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Company Name',
      hint: 'Enter company name',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateWorkingCompanyName(value),
      successMessage: 'Company name updated',
    );
  }

  Future<void> _showWorkingJobTitleDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.workingJobTitle ?? '');
    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Job Title',
      hint: 'Enter job title',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateWorkingJobTitle(value),
      successMessage: 'Job title updated',
    );
  }

  Future<void> _showWorkingOfficeAddressDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.workingOfficeAddress ?? '');
    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Office Address',
      hint: 'Enter office address',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateWorkingOfficeAddress(value),
      successMessage: 'Office address updated',
    );
  }

  Future<void> _showWorkingWorkEmailDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.workingWorkEmail ?? '');
    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Work Email (Optional)',
      hint: 'Enter work email',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateWorkingWorkEmail(value),
      successMessage: 'Work email updated',
    );
  }

  Future<void> _showSelfEmployedBusinessNameDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.selfEmployedBusinessName ?? '');
    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Business Name',
      hint: 'Enter business name',
      controller: controller,
      onSave: (value) => ref
          .read(professionalDetailsControllerProvider)
          .updateSelfEmployedBusinessName(value),
      successMessage: 'Business name updated',
    );
  }

  Future<void> _showSelfEmployedNatureOfWorkDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.selfEmployedNatureOfWork ?? '');
    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Nature of Work',
      hint: 'Describe your work',
      controller: controller,
      onSave: (value) => ref
          .read(professionalDetailsControllerProvider)
          .updateSelfEmployedNatureOfWork(value),
      successMessage: 'Nature of work updated',
    );
  }

  Future<void> _showSelfEmployedOfficeAddressDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.selfEmployedOfficeAddress ?? '');
    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Office Address',
      hint: 'Enter office address (if any)',
      controller: controller,
      onSave: (value) => ref
          .read(professionalDetailsControllerProvider)
          .updateSelfEmployedOfficeAddress(value),
      successMessage: 'Office address updated',
    );
  }

  // OWNER TYPE DIALOG
  Future<void> _showOwnerTypeDialog(BuildContext context, WidgetRef ref) async {
    final types = [
      'Individual',
      'Broker',
      'Professional Landlord',
      'Company',
    ];
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    String selected = _ownerTypeLabel(current?.ownerType);
    if (!types.contains(selected)) {
      selected = types.first;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Owner Type'),
              content: DropdownButton<String>(
                value: selected,
                isExpanded: true,
                items: types
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selected = value ?? types.first;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(professionalDetailsControllerProvider)
                          .updateOwnerType(selected);
                      ref.invalidate(professionalDetailsProvider);
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _showMessage(context, 'Owner type updated');
                    } catch (e) {
                      _showMessage(context, _formatSaveError(e));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _ownerTypeLabel(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    if (normalized.isEmpty) return 'Individual';
    if (normalized == 'individual' || normalized == 'individual owner') {
      return 'Individual';
    }
    if (normalized == 'company' || normalized == 'company / developer') {
      return 'Company';
    }
    if (normalized == 'broker') {
      return 'Broker';
    }
    if (normalized == 'professional landlord' || normalized == 'professional_landlord') {
      return 'Professional Landlord';
    }
    return 'Individual';
  }

  // YEARS OF EXPERIENCE DIALOG
  Future<void> _showYearsOfExperienceDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(
      text: current?.yearsOfExperience?.toString() ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Years of Ownership Experience'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter number of years',
              suffixText: 'years',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final years = controller.text.trim();
                if (years.isEmpty) return;
                final parsed = int.tryParse(years);
                if (parsed == null) {
                  _showMessage(context, 'Please enter a valid number');
                  return;
                }
                try {
                  await ref
                      .read(professionalDetailsControllerProvider)
                      .updateYearsOfExperience(parsed);
                  ref.invalidate(professionalDetailsProvider);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _showMessage(context, 'Experience updated');
                } catch (e) {
                  _showMessage(context, _formatSaveError(e));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // CITY DIALOG
  Future<void> _showCityDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.city ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Select City'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter your city',
              prefixIcon: Icon(Icons.location_city),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final city = controller.text.trim();
                if (city.isEmpty) return;
                try {
                  await ref.read(professionalDetailsControllerProvider).updateCity(city);
                  ref.invalidate(professionalDetailsProvider);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _showMessage(context, 'City updated');
                } catch (e) {
                  _showMessage(context, _formatSaveError(e));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // EMERGENCY CONTACT DIALOG
  Future<void> _showEmergencyContactDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.emergencyContact ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Emergency Contact Number'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              hintText: 'Enter emergency contact',
              prefixText: '+91 ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final contact = controller.text.trim();
                if (contact.isEmpty) return;
                try {
                  await ref
                      .read(professionalDetailsControllerProvider)
                      .updateEmergencyContact(contact);
                  ref.invalidate(professionalDetailsProvider);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _showMessage(context, 'Emergency contact saved');
                } catch (e) {
                  _showMessage(context, _formatSaveError(e));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showEmergencyVerificationDialog(BuildContext context, WidgetRef ref) async {
    final otpController = TextEditingController();
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final emergency = current?.emergencyContact?.trim() ?? '';

    if (emergency.isEmpty) {
      _showMessage(context, 'Please add emergency contact first');
      return;
    }

    try {
      final normalized = _normalizeIndianPhone(emergency);
      if (normalized == null || normalized.isEmpty) {
        _showMessage(context, 'Invalid phone number format');
        return;
      }

      // Send direct SMS OTP for emergency contact verification.
      await Supabase.instance.client.auth.signInWithOtp(
        phone: normalized,
        shouldCreateUser: false,
        channel: OtpChannel.sms,
      );

      if (!context.mounted) return;
      _showMessage(context, 'OTP sent to $normalized');

      // Show OTP verification dialog
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Verify Emergency Number'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter OTP sent to:',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.phone, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        normalized,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade800,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        letterSpacing: 8,
                        fontWeight: FontWeight.w600,
                      ),
                  decoration: InputDecoration(
                    hintText: '000000',
                    hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade300,
                          letterSpacing: 8,
                        ),
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final otp = otpController.text.trim();
                  if (otp.length < 4) {
                    _showMessage(context, 'Please enter valid OTP');
                    return;
                  }

                  try {
                    // Verify OTP via Supabase auth
                    await Supabase.instance.client.auth.verifyOTP(
                      phone: normalized,
                      token: otp,
                      type: OtpType.sms,
                    );

                    // Mark emergency contact as verified in profiles
                    await ref
                        .read(professionalDetailsControllerProvider)
                        .updateEmergencyContactVerified(true);

                    ref.invalidate(professionalDetailsProvider);
                    if (!dialogContext.mounted) return;
                    Navigator.pop(dialogContext);
                    _showMessage(context, 'Emergency number verified successfully ✓');
                  } on AuthException catch (error) {
                    _showMessage(context, error.message);
                  } catch (e) {
                    _showMessage(context, _formatSaveError(e));
                  }
                },
                icon: const Icon(Icons.verified_user, size: 18),
                label: const Text('Verify OTP'),
              ),
            ],
          );
        },
      );
    } on AuthException catch (error) {
      final message = error.message.toLowerCase();
      if (message.contains('rate') || message.contains('limit')) {
        _showMessage(context, 'Too many OTP requests. Please wait 60 seconds and try again.');
      } else if (message.contains('invalid') && message.contains('phone')) {
        _showMessage(
          context,
          'Phone format rejected by server. Use 10-digit mobile number without spaces.',
        );
      } else if (message.contains('sms') ||
          message.contains('provider') ||
          message.contains('twilio')) {
        _showMessage(
          context,
          'SMS provider is not configured in Supabase. Configure Twilio/MessageBird first.',
        );
      } else {
        _showMessage(context, error.message);
      }
    } catch (e) {
      _showMessage(context, _formatSaveError(e));
    }
  }

  // ID TYPE DIALOG
  Future<void> _showIDTypeDialog(BuildContext context, WidgetRef ref) async {
    final idTypes = ['Aadhaar', 'PAN', 'Passport', 'Voter ID'];
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    String selected = current?.idType ?? 'Aadhaar';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Government ID Type'),
              content: DropdownButton<String>(
                value: selected,
                isExpanded: true,
                items: idTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selected = value ?? 'Aadhaar';
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(professionalDetailsControllerProvider)
                          .updateGovernmentIdType(selected);
                      ref.invalidate(professionalDetailsProvider);
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _showMessage(context, 'ID type updated');
                    } catch (e) {
                      _showMessage(context, _formatSaveError(e));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ID NUMBER DIALOG
  Future<void> _showIDNumberDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Enter ID Number'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter your ID number',
              helperText: 'Numbers will be masked for security',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final idNumber = controller.text.trim();
                if (idNumber.isEmpty) return;
                if (idNumber.length < 4) {
                  _showMessage(context, 'ID number should be at least 4 characters');
                  return;
                }
                try {
                  await ref
                      .read(professionalDetailsControllerProvider)
                      .updateGovernmentIdNumberMasked(idNumber);
                  ref.invalidate(professionalDetailsProvider);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _showMessage(context, 'ID number saved securely');
                } catch (e) {
                  _showMessage(context, _formatSaveError(e));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // ID DOCUMENT UPLOAD DIALOG
  Future<void> _showIDUploadDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final urlController = TextEditingController();
    String selectedType = current?.idType ?? 'Aadhaar';
    final idTypes = ['Aadhaar', 'PAN', 'Passport', 'Voter ID'];

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Upload Government ID Document'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Upload a clear photo or scanned copy of your ${selectedType}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: 'ID Type'),
                      items: idTypes
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedType = value ?? 'Aadhaar';
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: urlController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Document URL',
                        hintText: 'Paste secure document URL from storage (e.g., Cloud Storage link)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ensure document is clear and readable. We\'ll verify and notify you.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final url = urlController.text.trim();
                    if (url.isEmpty) {
                      _showMessage(context, 'Please enter a document URL');
                      return;
                    }
                    try {
                      // Save document URL to government ID fields
                      await ref
                          .read(professionalDetailsControllerProvider)
                          .updateGovernmentIdDocumentUrl(url);
                      // Also update ID type if changed
                      await ref
                          .read(professionalDetailsControllerProvider)
                          .updateGovernmentIdType(selectedType);
                      // Optionally save to property_verifications for additional tracking
                      await ref.read(professionalDetailsControllerProvider).upsertPropertyVerification(
                            documentType: selectedType,
                            documentUrl: url,
                          );
                      ref.invalidate(professionalDetailsProvider);
                      if (!dialogContext.mounted) return;
                      Navigator.pop(dialogContext);
                      _showMessage(context, 'Document uploaded. Verification in progress.');
                    } catch (e) {
                      _showMessage(context, _formatSaveError(e));
                    }
                  },
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showCompanyNameDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.companyName ?? '');

    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Company Name',
      hint: 'Enter company name',
      controller: controller,
      onSave: (value) => ref
          .read(professionalDetailsControllerProvider)
          .updateCompanyName(value),
      successMessage: 'Company name updated',
    );
  }

  Future<void> _showAuthorizedPersonNameDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.authorizedPersonName ?? '');

    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Authorized Person Name',
      hint: 'Enter authorized person name',
      controller: controller,
      onSave: (value) => ref
          .read(professionalDetailsControllerProvider)
          .updateAuthorizedPersonName(value),
      successMessage: 'Authorized person name updated',
    );
  }

  Future<void> _showGstNumberDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.gstNumber ?? '');

    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'GST Number',
      hint: 'Enter GST number',
      controller: controller,
      onSave: (value) => ref
          .read(professionalDetailsControllerProvider)
          .updateGstNumber(value),
      successMessage: 'GST number updated',
    );
  }

  Future<void> _showCinNumberDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.cinNumber ?? '');

    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'CIN Number',
      hint: 'Enter CIN number',
      controller: controller,
      onSave: (value) => ref
          .read(professionalDetailsControllerProvider)
          .updateCinNumber(value),
      successMessage: 'CIN number updated',
    );
  }

  Future<void> _showAuthorizedPersonPanDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.authorizedPersonPan ?? '');

    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Authorized Person PAN',
      hint: 'Enter PAN number',
      controller: controller,
      onSave: (value) => ref
          .read(professionalDetailsControllerProvider)
          .updateAuthorizedPersonPan(value),
      successMessage: 'Authorized person PAN updated',
    );
  }

  Future<void> _showBrokerAgencyNameDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.brokerAgencyName ?? '');

    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Agency Name',
      hint: 'Enter brokerage agency name',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateBrokerAgencyName(value),
      successMessage: 'Agency name updated',
    );
  }

  Future<void> _showBrokerReraNumberDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.brokerReraNumber ?? '');

    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'RERA Number',
      hint: 'Enter RERA registration number',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateBrokerReraNumber(value),
      successMessage: 'RERA number updated',
    );
  }

  Future<void> _showBrokerLicenseNumberDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.brokerLicenseNumber ?? '');

    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Broker License Number',
      hint: 'Enter broker license number',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateBrokerLicenseNumber(value),
      successMessage: 'Broker license number updated',
    );
  }

  Future<void> _showLandlordBusinessNameDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.landlordBusinessName ?? '');

    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Business Name',
      hint: 'Enter business name',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateLandlordBusinessName(value),
      successMessage: 'Business name updated',
    );
  }

  Future<void> _showLandlordTotalPropertiesDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(
      text: current?.landlordTotalPropertiesOwned?.toString() ?? '',
    );

    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Total Properties Owned',
      hint: 'Enter total properties count',
      controller: controller,
      onSave: (value) => ref
          .read(professionalDetailsControllerProvider)
          .updateLandlordTotalPropertiesOwned(value),
      successMessage: 'Total properties updated',
    );
  }

  Future<void> _showLandlordPanNumberDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.landlordPanNumber ?? '');

    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Landlord PAN',
      hint: 'Enter landlord PAN number',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateLandlordPanNumber(value),
      successMessage: 'Landlord PAN updated',
    );
  }

  Future<void> _showIndividualOccupationDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.individualOccupation ?? '');

    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Occupation',
      hint: 'Enter occupation',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateIndividualOccupation(value),
      successMessage: 'Occupation updated',
    );
  }

  Future<void> _showIndividualAddressDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.individualAddress ?? '');

    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Address',
      hint: 'Enter address',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateIndividualAddress(value),
      successMessage: 'Address updated',
    );
  }

  Future<void> _showIndividualPanNumberDialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.individualPanNumber ?? '');

    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Individual PAN',
      hint: 'Enter PAN number',
      controller: controller,
      onSave: (value) =>
          ref.read(professionalDetailsControllerProvider).updateIndividualPanNumber(value),
      successMessage: 'Individual PAN updated',
    );
  }

  Future<void> _showIndividualAadhaarLast4Dialog(BuildContext context, WidgetRef ref) async {
    final current = ref.read(professionalDetailsProvider).valueOrNull;
    final controller = TextEditingController(text: current?.individualAadhaarLast4 ?? '');

    await _showSimpleTextSaveDialog(
      context: context,
      ref: ref,
      title: 'Aadhaar Last 4 Digits',
      hint: 'Enter last 4 digits',
      controller: controller,
      onSave: (value) => ref
          .read(professionalDetailsControllerProvider)
          .updateIndividualAadhaarLast4(value),
      successMessage: 'Aadhaar last 4 digits updated',
    );
  }

  Future<void> _showSimpleTextSaveDialog({
    required BuildContext context,
    required WidgetRef ref,
    required String title,
    required String hint,
    required TextEditingController controller,
    required Future<void> Function(String value) onSave,
    required String successMessage,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hint),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final value = controller.text.trim();
                if (value.isEmpty) return;
                try {
                  await onSave(value);
                  ref.invalidate(professionalDetailsProvider);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  _showMessage(context, successMessage);
                } catch (e) {
                  _showMessage(context, _formatSaveError(e));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImageUrlDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Upload Profile Image'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Paste image URL',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final imageUrl = controller.text.trim();
                if (imageUrl.isEmpty) {
                  return;
                }

                try {
                  await ref.read(profileUiStateProvider.notifier).updateProfileImage(imageUrl);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                } on AuthException catch (error) {
                  _showMessage(context, error.message);
                } catch (_) {
                  _showMessage(context, 'Unable to update profile image.');
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await AuthController().signOut();
      if (!context.mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    } on AuthException catch (error) {
      _showMessage(context, error.message);
    } catch (_) {
      _showMessage(context, 'Unable to logout right now.');
    }
  }

  String? _normalizeIndianPhone(String rawPhone) {
    var normalized = rawPhone.trim();
    normalized = normalized.replaceAll(RegExp(r'[^0-9+]'), '');

    if (normalized.startsWith('+')) {
      normalized = normalized.substring(1);
    }

    if (normalized.startsWith('91') && normalized.length == 12) {
      normalized = normalized.substring(2);
    }

    if (normalized.length == 11 && normalized.startsWith('0')) {
      normalized = normalized.substring(1);
    }

    // Indian mobile numbers are 10 digits and usually start from 6-9.
    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(normalized)) {
      return null;
    }

    return '+91$normalized';
  }

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatSaveError(Object error) {
    if (error is PostgrestException) {
      if (error.code == '42P01') {
        return 'Backend table missing. Run OWNER_PROFESSIONAL_DETAILS_SCHEMA.sql in Supabase.';
      }
      if (error.code == '42703' || error.message.toLowerCase().contains('relatives_emails')) {
        return 'Relatives column missing. Run PROFILES_RELATIVES_EMAILS_MIGRATION.sql in Supabase.';
      }
      if (error.code == '42501') {
        return 'Permission denied by RLS policy. Please allow update/insert for current user.';
      }
      return error.message;
    }
    return 'Unable to save. Please try again.';
  }

  // EDIT FULL NAME DIALOG (from profiles table)
  Future<void> _showEditFullNameDialog(
    BuildContext context,
    WidgetRef ref,
    String currentName,
  ) async {
    final controller = TextEditingController(text: currentName);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Full Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter your full name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedName = controller.text.trim();
                if (updatedName.isEmpty) {
                  return;
                }

                try {
                  await ref.read(profileDataControllerProvider).updateFullName(updatedName);
                  ref.invalidate(profileDataProvider);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    _showMessage(context, 'Full name updated');
                  }
                } catch (e) {
                  _showMessage(context, _formatSaveError(e));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // EDIT CITY DIALOG (from profiles table)
  Future<void> _showEditCityDialog(
    BuildContext context,
    WidgetRef ref,
    String currentCity,
  ) async {
    final controller = TextEditingController(text: currentCity);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit City'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter your city'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedCity = controller.text.trim();
                if (updatedCity.isEmpty) {
                  return;
                }

                try {
                  await ref.read(profileDataControllerProvider).updateCity(updatedCity);
                  ref.invalidate(profileDataProvider);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    _showMessage(context, 'City updated');
                  }
                } catch (e) {
                  _showMessage(context, _formatSaveError(e));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // EDIT ROLE DIALOG (from profiles table)
  String _roleLabel(String raw) {
    final normalized = raw.trim().toLowerCase();
    if (normalized == 'renter') return 'User';
    if (normalized == 'owner') return 'Owner';
    if (normalized == 'admin') return 'Admin';
    if (normalized.isEmpty) return 'Not specified';
    return raw;
  }

  Future<void> _showEditRoleDialog(
    BuildContext context,
    WidgetRef ref,
    String currentRole,
  ) async {
    final roles = ['owner', 'renter', 'admin'];
    String selected = currentRole.isEmpty ? 'owner' : currentRole;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Role'),
              content: DropdownButton<String>(
                value: selected,
                isExpanded: true,
                items: roles
                    .map((e) => DropdownMenuItem(value: e, child: Text(_roleLabel(e))))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selected = value ?? 'owner';
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref.read(profileDataControllerProvider).updateRole(selected);
                      ref.invalidate(profileDataProvider);
                      ref.invalidate(userRoleProvider);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        _showMessage(context, 'Role updated');
                      }
                    } catch (e) {
                      _showMessage(context, _formatSaveError(e));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // EDIT BUDGET DIALOG (from profiles table - for renters)
  Future<void> _showEditBudgetDialog(
    BuildContext context,
    WidgetRef ref,
    String currentBudget,
  ) async {
    final controller = TextEditingController(text: currentBudget);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit Budget'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'Enter your budget range'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedBudget = controller.text.trim();
                if (updatedBudget.isEmpty) {
                  return;
                }

                try {
                  await ref.read(profileDataControllerProvider).updateBudget(updatedBudget);
                  ref.invalidate(profileDataProvider);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    _showMessage(context, 'Budget updated');
                  }
                } catch (e) {
                  _showMessage(context, _formatSaveError(e));
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // EDIT PROPERTY TYPE DIALOG (from profiles table - for owners)
  Future<void> _showEditPropertyTypeDialog(
    BuildContext context,
    WidgetRef ref,
    String currentPropertyType,
  ) async {
    final propertyTypes = ['apartment', 'house', 'villa', 'studio', 'shared'];
    String selected = currentPropertyType.isEmpty ? 'apartment' : currentPropertyType;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Select Property Type'),
              content: DropdownButton<String>(
                value: selected,
                isExpanded: true,
                items: propertyTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selected = value ?? 'apartment';
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(profileDataControllerProvider)
                          .updatePropertyType(selected);
                      ref.invalidate(profileDataProvider);
                      if (dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        _showMessage(context, 'Property type updated');
                      }
                    } catch (e) {
                      _showMessage(context, _formatSaveError(e));
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}