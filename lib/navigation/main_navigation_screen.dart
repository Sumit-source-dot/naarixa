import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/widgets/app_drawer.dart';
import '../config/routes.dart';
import '../features/auth/auth_controller.dart';
import '../features/accommodation/presentation/screens/accommodation_screen.dart';
import '../features/bookings/book_screen.dart';
import '../features/auth/providers/user_role_provider.dart';
import '../features/profile/presentation/providers/profile_provider.dart';
import '../features/complaints/presentation/screens/complaints_screen.dart';
import '../features/cabs/screens/cabs_home_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/safety/routes/presentation/screens/safest_route_screen.dart';
import '../features/sos/controllers/sos_controller.dart';
import '../providers/navigation_provider.dart';
import 'bottom_nav.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  final SosController _sosController = SosController();
  bool _sosActive = false;
  dynamic _activeSosId;

  List<Widget> _pagesForRole(String role) {
    if (role == 'owner') {
      return const [
        HomeScreen(),
        AccommodationScreen(),
        BookScreen(),
        ComplaintsScreen(),
        ProfileScreen(),
      ];
    }

    return [
      HomeScreen(),
      CabsHomeScreen(),
      SafestRouteScreen(),
      BookScreen(),
      ProfileScreen(),
    ];
  }

  List<BottomNavigationBarItem> _bottomItemsForRole(String role) {
    if (role == 'owner') {
      return const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.apartment_outlined), label: 'Properties'),
        BottomNavigationBarItem(icon: Icon(Icons.inbox_outlined), label: 'Requests'),
        BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Complaints'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ];
    }

    return const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(icon: Icon(Icons.local_taxi_outlined), label: 'Cabs'),
      BottomNavigationBarItem(icon: Icon(Icons.shield), label: 'Route'),
      BottomNavigationBarItem(icon: Icon(Icons.book_online_outlined), label: 'Bookings'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ];
  }

  @override
  void dispose() {
    _sosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomTabIndexProvider);
    final profile = ref.watch(profileUiStateProvider);
    final roleAsync = ref.watch(userRoleProvider);
    final role = roleAsync.valueOrNull;
    final colorScheme = Theme.of(context).colorScheme;

    if (role == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = _pagesForRole(role);
    final navItems = _bottomItemsForRole(role);
    final safeIndex = currentIndex.clamp(0, pages.length - 1);

    return Scaffold(
      drawer: roleAsync.when(
        data: (role) => AppDrawer(
          role: role,
          onSelectTab: (index) {
            ref.read(bottomTabIndexProvider.notifier).state = index;
          },
        ),
        loading: () => const Drawer(
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (_, __) => AppDrawer(
          role: 'renter',
          onSelectTab: (index) {
            ref.read(bottomTabIndexProvider.notifier).state = index;
          },
        ),
      ),
      appBar: AppBar(
        title: const Text('Naarixa'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.notifications),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showProfileMenu(context, ref),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: colorScheme.surfaceVariant,
                child: ClipOval(
                  child: profile.imageUrl.isEmpty
                      ? const Icon(Icons.person_outline, size: 18)
                      : SizedBox.expand(
                          child: Image.network(
                            profile.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person_outline, size: 18);
                            },
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return const Center(
                                child: SizedBox(
                                  height: 12,
                                  width: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(index: safeIndex, children: pages),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _sosActive ? colorScheme.primary : colorScheme.error,
        foregroundColor: _sosActive ? colorScheme.onPrimary : colorScheme.onError,
        onPressed: () async {
          if (_sosActive) {
            try {
              final userId = Supabase.instance.client.auth.currentUser?.id;
              await _sosController.stopSOS(
                sosId: _activeSosId,
                userId: userId,
              );
              if (!mounted) return;
              setState(() {
                _sosActive = false;
                _activeSosId = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🛑 SOS stopped')),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to stop SOS: $e')),
              );
            }
            return;
          }

          final sosId = await _sosController.triggerEmergencyFlow(
            context,
            isMounted: () => mounted,
          );
          if (!mounted) return;
          if (sosId != null) {
            setState(() {
              _sosActive = true;
              _activeSosId = sosId;
            });
          }
        },
        icon: Icon(_sosActive ? Icons.stop_circle_outlined : Icons.sos),
        label: Text(_sosActive ? 'Stop SOS' : 'SOS'),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: safeIndex,
        items: navItems,
        onTap: (index) => ref.read(bottomTabIndexProvider.notifier).state = index,
      ),
    );
  }


  Future<void> _showProfileMenu(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('View Profile'),
                  onTap: () {
                    ref.read(bottomTabIndexProvider.notifier).state = 4;
                    Navigator.pop(sheetContext);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit Profile'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _showEditNameDialog(context, ref);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.shield_outlined),
                  title: const Text('Safety Settings'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Safety Settings placeholder.'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notification Settings'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Navigator.of(context).pushNamed(AppRoutes.notifications);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Upload Profile Image'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showImageUrlDialog(context, ref);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Logout'),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    await _handleLogout(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditNameDialog(BuildContext context, WidgetRef ref) async {
    final currentName = ref.read(profileUiStateProvider).name;
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
                final name = controller.text.trim();
                if (name.isEmpty) {
                  return;
                }

                try {
                  await ref
                      .read(profileUiStateProvider.notifier)
                      .updateName(name);
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

  Future<void> _showImageUrlDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Upload Profile Image'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Paste image URL'),
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
                  await ref
                      .read(profileUiStateProvider.notifier)
                      .updateProfileImage(imageUrl);
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

  void _showMessage(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}