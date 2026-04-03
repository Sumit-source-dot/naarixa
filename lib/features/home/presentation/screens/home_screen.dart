import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/routes.dart';
import '../../../../providers/navigation_provider.dart';
import '../../../auth/providers/user_role_provider.dart';
import '../../../profile/presentation/providers/profile_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileUiStateProvider);
    final roleAsync = ref.watch(userRoleProvider);
    final role = roleAsync.valueOrNull;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final name = profile.name.trim().isEmpty
        ? 'Naarixa User'
        : profile.name.trim();
    final infoGradient = theme.brightness == Brightness.dark
        ? LinearGradient(
            colors: [colorScheme.surfaceVariant, colorScheme.surface],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFE7F3EF), Color(0xFFF7F3F1)],
          );

    if (role == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final isOwner = role == 'owner';
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _HeroSection(name: name),
          const SizedBox(height: 20),
          _SectionHeader(
            title: 'Safety first, always',
            subtitle: 'Choose the right safety tool in one tap.',
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AnimatedFeatureCard(
                  index: 0,
                  title: 'Safe accommodations',
                  subtitle: 'Verified stays and trusted owners',
                  icon: Icons.shield_outlined,
                  color: const Color(0xFF2F6B5C),
                  onTap: () => _goToTab(ref, isOwner ? 2 : 3),
                ),
                _AnimatedFeatureCard(
                  index: 1,
                  title: 'Emergency SOS',
                  subtitle: 'Rapid help and live tracking',
                  icon: Icons.sos_rounded,
                  color: const Color(0xFFB8464D),
                  onTap: () => _showSosHint(context),
                ),
                _AnimatedFeatureCard(
                  index: 2,
                  title: 'Cab services',
                  subtitle: 'Trusted rides with ETA',
                  icon: Icons.local_taxi_outlined,
                  color: const Color(0xFF3D5A80),
                  onTap: () => _goToTab(ref, isOwner ? 0 : 1),
                ),
                _AnimatedFeatureCard(
                  index: 3,
                  title: 'Safest routes',
                  subtitle: 'Well lit routes for peace',
                  icon: Icons.route_outlined,
                  color: const Color(0xFF6B4E71),
                  onTap: () => _goToTab(ref, isOwner ? 0 : 2),
                ),
                _AnimatedFeatureCard(
                  index: 4,
                  title: 'Bookings',
                  subtitle: 'Track requests and stays',
                  icon: Icons.book_online_outlined,
                  color: const Color(0xFF1B707E),
                  onTap: () => _goToTab(ref, isOwner ? 2 : 3),
                ),
                _AnimatedFeatureCard(
                  index: 5,
                  title: 'Complaints & support',
                  subtitle: 'We respond fast',
                  icon: Icons.support_agent,
                  color: const Color(0xFF7B5E3B),
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.complaints),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: 'Your trust toolkit',
            subtitle: 'Everything you need to stay informed.',
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                _InfoTile(
                  title: 'Notifications and alerts',
                  subtitle: 'Safety updates and booking status',
                  icon: Icons.notifications_none_rounded,
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.notifications),
                ),
                const SizedBox(height: 12),
                _InfoTile(
                  title: 'Profile safety checklist',
                  subtitle: 'Keep your details verified',
                  icon: Icons.verified_user_outlined,
                  onTap: () => _goToTab(ref, 4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: infoGradient,
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F6B5C),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.favorite, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'We are with you, always',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Naarixa keeps every step secure with verified stays and instant SOS support.',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _goToTab(WidgetRef ref, int index) {
    ref.read(bottomTabIndexProvider.notifier).state = index;
  }

  void _showSosHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tap the SOS button to trigger emergency assistance.'),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 600),
        tween: Tween(begin: 0, end: 1),
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 12 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          height: 230,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            image: const DecorationImage(
              image: NetworkImage(
                'https://static.vecteezy.com/system/resources/thumbnails/035/349/047/small_2x/ai-generated-a-girl-in-a-business-attire-posing-on-gray-background-free-photo.jpg',
              ),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.25),
                blurRadius: 20,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.black.withOpacity(0.15),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Welcome back, $name',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontFamily: 'PlayfairDisplay',
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Stay safe, stay supported. Every stay, ride, and route is designed for your comfort and trust.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Colors.white70,
                        fontFamily: 'Manrope',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: const [
                        _HeroChip(label: 'Verified listings'),
                        SizedBox(width: 8),
                        _HeroChip(label: '24/7 support'),
                        SizedBox(width: 8),
                        _HeroChip(label: 'Live SOS'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Colors.white),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              fontFamily: 'PlayfairDisplay',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontFamily: 'Manrope',
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedFeatureCard extends StatelessWidget {
  const _AnimatedFeatureCard({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final int index;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.of(context).size.width - 52) / 2;
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 80)),
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 8 * (1 - value)),
            child: child,
          ),
        );
      },
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: color.withOpacity(0.08),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'Manrope',
                ),
              ),
              const SizedBox(height: 6),
              Text(subtitle, style: const TextStyle(fontSize: 11, height: 1.3)),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}


