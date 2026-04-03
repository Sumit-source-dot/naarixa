import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/auth_controller.dart';
import '../../config/routes.dart';
import '../../shared/widgets/owner_trust_score_widget.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';

class AppDrawer extends ConsumerWidget {
  final String role;
  final ValueChanged<int>? onSelectTab;

  const AppDrawer({super.key, required this.role, this.onSelectTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileUiStateProvider);
    return Drawer(
      child: Column(
        children: [
          _buildHeader(context, profile),
          if (role == 'owner')
            OwnerTrustScoreWidget(
              onTap: () => Navigator.pop(context),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: [
                _sectionLabel(context, 'Main'),
                ..._mainItems(context, role),
                const SizedBox(height: 8),
                const Divider(),
                _sectionLabel(context, 'Safety & Support'),
                ..._supportItems(context),
                const SizedBox(height: 8),
                const Divider(),
                _sectionLabel(context, 'Account'),
                ..._accountItems(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ProfileUiState profile) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = profile.name.trim().isEmpty ? 'Naarixa User' : profile.name.trim();
    final email = profile.email.trim().isEmpty ? 'Welcome back' : profile.email.trim();
    return UserAccountsDrawerHeader(
      decoration: BoxDecoration(color: colorScheme.primary),
      accountName: Text(
        displayName,
        style: TextStyle(color: colorScheme.onPrimary),
      ),
      accountEmail: Text(
        email,
        style: TextStyle(color: colorScheme.onPrimary.withOpacity(0.8)),
      ),
      currentAccountPicture: CircleAvatar(
        backgroundColor: colorScheme.onPrimary,
        backgroundImage: profile.imageUrl.trim().isEmpty
            ? null
            : NetworkImage(profile.imageUrl.trim()),
        child: profile.imageUrl.trim().isEmpty
            ? Icon(Icons.person, color: colorScheme.primary)
            : null,
      ),
    );
  }

  List<Widget> _mainItems(BuildContext context, String role) {
    if (role == 'owner') {
      return [
        _tile(context, Icons.dashboard_outlined, 'Dashboard', onTap: () => _selectTab(context, 0)),
        _tile(context, Icons.apartment_outlined, 'Properties', onTap: () => _selectTab(context, 1)),
        _tile(context, Icons.inbox_outlined, 'Requests', onTap: () => _selectTab(context, 2)),
        _tile(context, Icons.campaign, 'Complaints', onTap: () => _selectTab(context, 3)),
        _tile(context, Icons.person, 'Profile', onTap: () => _selectTab(context, 4)),
      ];
    }

    return [
      _tile(context, Icons.home, 'Home', onTap: () => _selectTab(context, 0)),
      _tile(
        context,
        Icons.shield_outlined,
        'Safe Routes / Cabs',
        onTap: () => _showSafetyModePicker(context),
      ),
      _tile(context, Icons.book_online_outlined, 'Bookings', onTap: () => _selectTab(context, 3)),
      _tile(context, Icons.person, 'Profile', onTap: () => _selectTab(context, 4)),
    ];
  }

  List<Widget> _supportItems(BuildContext context) {
    return [
      _tile(
        context,
        Icons.sos_rounded,
        'SOS / Emergency',
        onTap: () => Navigator.pushNamed(context, AppRoutes.sosEmergency),
      ),
      _tile(
        context,
        Icons.call_outlined,
        'All Helplines',
        onTap: () => Navigator.pushNamed(context, AppRoutes.helplines),
      ),
      _tile(
        context,
        Icons.report_outlined,
        'Complaints / Report Issue',
        onTap: () => Navigator.pushNamed(context, AppRoutes.complaints),
      ),
      _tile(
        context,
        Icons.notifications_none_rounded,
        'Notifications',
        onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
      ),
      _tile(
        context,
        Icons.lightbulb_outline,
        'Safety Tips',
        onTap: () => Navigator.pushNamed(context, AppRoutes.safetyTips),
      ),
    ];
  }

  List<Widget> _accountItems(BuildContext context) {
    return [
      _tile(
        context,
        Icons.settings_outlined,
        'Settings',
        onTap: () => Navigator.pushNamed(context, AppRoutes.settings),
      ),
      _tile(context, Icons.logout, 'Logout', isLogout: true),
    ];
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  void _selectTab(BuildContext context, int index) {
    onSelectTab?.call(index);
  }

  void _showSafetyModePicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.local_taxi_outlined),
                  title: const Text('Cabs'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onSelectTab?.call(1);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shield),
                  title: const Text('Safe Routes'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onSelectTab?.call(2);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title, {
    VoidCallback? onTap,
    bool isLogout = false,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: () async {
        Navigator.pop(context);

        if (isLogout) {
          await AuthController().signOut();
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.login,
            (route) => false,
          );
        } else if (onTap != null) {
          onTap();
        }
      },
    );
  }
}