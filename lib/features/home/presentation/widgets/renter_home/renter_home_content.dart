import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../section_header.dart';
import 'budget_banner.dart';
import 'category_row.dart';
import 'how_it_works.dart';
import 'mock_data.dart';
import 'nav_icon_button.dart';
import 'promo_banner.dart';
import 'property_lists.dart';
import 'renter_properties_provider.dart';
import 'safety_banner.dart';
import 'testimonial_banner.dart';

class RenterHomeContent extends StatefulWidget {
  const RenterHomeContent({super.key});

  @override
  State<RenterHomeContent> createState() => _RenterHomeContentState();
}

class _RenterHomeContentState extends State<RenterHomeContent> {
  final Set<int> _favorites = {0, 5};

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          expandedHeight: 0,
          pinned: true,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          title: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: colorScheme.primary, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            'Ludhiana, Punjab',
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                            Icon(Icons.keyboard_arrow_down,
                              color: colorScheme.primary, size: 16),
                        ],
                      ),
                      Text(
                        'Find Your Home',
                        style: textTheme.headlineSmall?.copyWith(
                          fontFamily: 'Georgia',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    RenterNavIconButton(
                      icon: Icons.favorite_border_rounded,
                      badge: false,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    RenterNavIconButton(
                      icon: Icons.notifications_outlined,
                      badge: true,
                      onTap: () {},
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        'R',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          toolbarHeight: 70,
        ),
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              const RenterPromoBanner(),
              const SizedBox(height: 24),
              const RenterSafetyBanner(),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(title: 'Popular Picks', actionLabel: 'See all'),
              ),
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, _) {
                  final popularPropertiesAsync = ref.watch(renterPopularPropertiesProvider);

                  return popularPropertiesAsync.when(
                    data: (properties) {
                      if (properties.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          child: Text(
                            'No uploaded properties available yet.',
                            style: TextStyle(fontSize: 13),
                          ),
                        );
                      }

                      return RenterHorizontalPropertyList(
                        properties: properties,
                        favorites: _favorites,
                        onFavorite: (i) => setState(() {
                          if (_favorites.contains(i)) {
                            _favorites.remove(i);
                          } else {
                            _favorites.add(i);
                          }
                        }),
                      );
                    },
                    loading: () => SizedBox(
                      height: 220,
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                        ),
                      ),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Text(
                        err.toString().replaceFirst('Exception: ', ''),
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              const RenterBudgetBanner(),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(title: 'Near You', actionLabel: 'See all'),
              ),
              const SizedBox(height: 12),
              Consumer(
                builder: (context, ref, _) {
                  final popularCount =
                      ref.watch(renterPopularPropertiesProvider).valueOrNull?.length ?? 0;
                  return RenterNearbyPropertyList(
                    properties: nearbyRenterProperties,
                    baseIndex: popularCount,
                    favorites: _favorites,
                    onFavorite: (i) => setState(() {
                      if (_favorites.contains(i)) {
                        _favorites.remove(i);
                      } else {
                        _favorites.add(i);
                      }
                    }),
                  );
                },
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: SectionHeader(title: 'How It Works', actionLabel: null),
              ),
              const SizedBox(height: 12),
              const RenterHowItWorks(),
              const SizedBox(height: 24),
              const RenterTestimonialBanner(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}
