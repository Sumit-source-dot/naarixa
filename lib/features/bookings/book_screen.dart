import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../auth/providers/user_role_provider.dart';
import '../notifications/presentation/providers/notifications_provider.dart';
import 'presentation/widgets/renter_home/models.dart';
import 'presentation/widgets/renter_home/category_row.dart';
import 'presentation/widgets/renter_home/renter_properties_provider.dart';
import 'presentation/widgets/renter_home/search_bar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Property Booking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const BookScreen(),
    );
  }
}

class BookingRequest {
  final String id;
  final String? renterId;
  final String tenantName;
  final String tenantAvatar;
  final String? tenantImageUrl;
  final String propertyName;
  final String propertyImage;
  final String location;
  final String requestDate;
  final String moveInDate;
  final String duration;
  final double rentAmount;
  final String status;
  final String message;
  final int rating;
  final String? renterCity;
  final String? renterType;
  final String? renterBudget;
  final DateTime? renterCreatedAt;

  const BookingRequest({
    required this.id,
    this.renterId,
    required this.tenantName,
    required this.tenantAvatar,
    this.tenantImageUrl,
    required this.propertyName,
    required this.propertyImage,
    required this.location,
    required this.requestDate,
    required this.moveInDate,
    required this.duration,
    required this.rentAmount,
    required this.status,
    required this.message,
    required this.rating,
    this.renterCity,
    this.renterType,
    this.renterBudget,
    this.renterCreatedAt,
  });
}

final ownerBookingRequestsProvider = FutureProvider<List<BookingRequest>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  if (user == null) {
    return const [];
  }

  final response = await supabase
      .from('booking_requests')
      .select('id, property_id, owner_id, renter_id, requested_price, message, status, created_at')
      .eq('owner_id', user.id)
      .order('created_at', ascending: false);

  if (response is! List || response.isEmpty) {
    return const [];
  }

  final rows = response.cast<Map<String, dynamic>>();
  final renterIds = rows
      .map((row) => (row['renter_id'] ?? '').toString().trim())
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();
  final propertyIds = rows
      .map((row) => (row['property_id'] ?? '').toString().trim())
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  final renterDirectory = <String, Map<String, dynamic>>{};
  if (renterIds.isNotEmpty) {
    try {
      final renters = await supabase
          .from('profiles')
          .select('id, full_name, name, avatar_url, image_url, profile_image_url, city, renter_type, budget, created_at')
          .inFilter('id', renterIds);
      for (final renter in (renters as List)) {
        final profile = renter as Map<String, dynamic>;
        final id = (profile['id'] ?? '').toString().trim();
        if (id.isNotEmpty) {
          renterDirectory[id] = profile;
        }
      }
    } catch (_) {}
  }

  final propertyDirectory = <String, Map<String, dynamic>>{};
  if (propertyIds.isNotEmpty) {
    try {
      final properties = await supabase
          .from('property')
          .select('id, title, location, budget, safetyscore, images, image, image_url')
          .inFilter('id', propertyIds);
      for (final property in (properties as List)) {
        final map = property as Map<String, dynamic>;
        final id = (map['id'] ?? '').toString().trim();
        if (id.isNotEmpty) {
          propertyDirectory[id] = map;
        }
      }
    } catch (_) {}
  }

  return rows.map((row) {
    final renterId = (row['renter_id'] ?? '').toString().trim();
    final propertyId = (row['property_id'] ?? '').toString().trim();

    final renter = renterDirectory[renterId];
    final property = propertyDirectory[propertyId];

    final tenantName = (renter?['full_name'] ?? renter?['name'] ?? 'User').toString().trim();
    final propertyName = (property?['title'] ?? 'Property').toString().trim();
    final location = (property?['location'] ?? 'Location not specified').toString().trim();
    final budget = (row['requested_price'] ?? property?['budget']);
    final rentAmount = budget is num ? budget.toDouble() : double.tryParse('$budget') ?? 0;

    final createdAt = DateTime.tryParse((row['created_at'] ?? '').toString());
    final rating = _ratingFromSafety(property?['safetyscore']);

    return BookingRequest(
      id: (row['id'] ?? '').toString(),
        renterId: renterId.isEmpty ? null : renterId,
      tenantName: tenantName.isEmpty ? 'User' : tenantName,
      tenantAvatar: _initialsFromName(tenantName),
              tenantImageUrl: (renter?['avatar_url'] ??
            renter?['image_url'] ??
            renter?['profile_image_url'])
          ?.toString()
          .trim(),
      propertyName: propertyName.isEmpty ? 'Property' : propertyName,
      propertyImage: _extractPropertyImage(property),
      location: location.isEmpty ? 'Location not specified' : location,
      requestDate: _formatDateShort(createdAt),
      moveInDate: 'Flexible',
      duration: 'Flexible',
      rentAmount: rentAmount,
      status: _normalizeRequestStatus((row['status'] ?? '').toString()),
      message: (row['message'] ?? '').toString().trim(),
      rating: rating,
      renterCity: renter?['city']?.toString(),
      renterType: renter?['renter_type']?.toString(),
      renterBudget: renter?['budget']?.toString(),
      renterCreatedAt: DateTime.tryParse((renter?['created_at'] ?? '').toString()),
    );
  }).toList();
});

int _ratingFromSafety(dynamic safetyValue) {
  if (safetyValue is num) {
    final mapped = 3.5 + (safetyValue.clamp(0, 100) / 100) * 1.5;
    final rounded = mapped.round();
    return rounded.clamp(1, 5);
  }
  return 4;
}

String _normalizeRequestStatus(String raw) {
  final value = raw.trim().toLowerCase();
  if (value == 'accepted' || value == 'declined' || value == 'pending') {
    return value;
  }
  return 'pending';
}

String _initialsFromName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((e) => e.isNotEmpty)
      .toList();
  if (parts.isEmpty) return 'RT';
  if (parts.length == 1) {
    final one = parts.first;
    return one.length >= 2 ? one.substring(0, 2).toUpperCase() : one.toUpperCase();
  }
  return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
}

String _formatDateShort(DateTime? date) {
  if (date == null) return 'N/A';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[(date.month - 1).clamp(0, 11)];
  return '$month ${date.day}, ${date.year}';
}

class BookScreen extends ConsumerStatefulWidget {
  const BookScreen({super.key});

  @override
  ConsumerState<BookScreen> createState() => _BookScreenState();
}

class _BookScreenState extends ConsumerState<BookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedFilter = 0;
  String _renterSearchQuery = '';
  String _selectedRenterType = 'All';
  static const double _defaultBudgetMin = 0;
  static const double _defaultBudgetMax = 200000;
  double _selectedMinBudget = _defaultBudgetMin;
  double _selectedMaxBudget = _defaultBudgetMax;
  static const List<String> _locationOptions = [
    'All',
    'Chandigarh',
    'Delhi',
    'Noida',
    'Gurugram',
    'Hyderabad',
    'Bengaluru',
    'Pune',
    'Mumbai and andheri',
  ];
  String _selectedLocation = 'All';

  static const List<Color> _categoryColors = [
    Color(0xFF6366F1),
    Color(0xFF10B981),
    Color(0xFFE8703A),
    Color(0xFFF59E0B),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
  ];

  static const List<Color> _categoryBgs = [
    Color(0xFFEDE9FE),
    Color(0xFFD1FAE5),
    Color(0xFFFFF4EE),
    Color(0xFFFEF3C7),
    Color(0xFFDBEAFE),
    Color(0xFFF3E8FF),
  ];

  static const List<String> _preferredRenterCategories = [
    'All',
    '1 BHK',
    '2 BHK',
    '3 BHK',
    'Flat',
    'Villa',
    'Studio',
    'PG',
  ];

  final List<String> _filters = ['All', 'Pending', 'Accepted', 'Declined'];
  final List<String> _renterFilters = ['All', 'Pending', 'Accepted', 'Active'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<BookingRequest> _applyOwnerFilters(List<BookingRequest> requests) {
    if (_selectedFilter == 0) return requests;
    final statusMap = ['all', 'pending', 'accepted', 'declined'];
    final status = statusMap[_selectedFilter];
    return requests.where((r) => r.status == status).toList();
  }

  List<RenterProperty> _applyRenterFilters(List<RenterProperty> properties) {
    final query = _renterSearchQuery.trim().toLowerCase();
    return properties.where((property) {
      final matchesType = _matchesRenterCategory(property, _selectedRenterType);
      final matchesLocation = _selectedLocation == 'All'
          ? true
          : _normalizeText(property.location)
              .contains(_normalizeText(_selectedLocation));
      final monthlyRent = _extractMonthlyRent(property);
      final hasBudget =
          _selectedMinBudget > _defaultBudgetMin || _selectedMaxBudget < _defaultBudgetMax;

      final matchesBudget = !hasBudget
          ? true
          : (monthlyRent != null &&
              monthlyRent >= _selectedMinBudget &&
              monthlyRent <= _selectedMaxBudget);

      if (query.isEmpty) {
        return matchesType && matchesBudget && matchesLocation;
      }

      final haystack =
          '${property.name} ${property.location} ${property.type} ${property.tags.join(' ')}'
              .toLowerCase();
      return matchesType && matchesBudget && matchesLocation && haystack.contains(query);
    }).toList();
  }

  List<RenterCategory> _buildRenterCategories(List<String> types) {
    final labels = <String>{..._preferredRenterCategories};
    for (final type in types) {
      final clean = type.trim();
      if (clean.isNotEmpty) {
        labels.add(clean);
      }
    }
    final ordered = labels.toList()
      ..sort((a, b) {
        final ia = _preferredRenterCategories.indexOf(a);
        final ib = _preferredRenterCategories.indexOf(b);
        if (ia == -1 && ib == -1) return a.compareTo(b);
        if (ia == -1) return 1;
        if (ib == -1) return -1;
        return ia.compareTo(ib);
      });

    return List.generate(ordered.length, (i) {
      final label = ordered[i];
      return RenterCategory(
        label: label,
        icon: _iconForType(label),
        color: _categoryColors[i % _categoryColors.length],
        bg: _categoryBgs[i % _categoryBgs.length],
      );
    });
  }

  IconData _iconForType(String type) {
    final value = type.toLowerCase();
    if (value.contains('studio')) return Icons.weekend_outlined;
    if (value.contains('1 bhk')) return Icons.single_bed_outlined;
    if (value.contains('2 bhk')) return Icons.bed_outlined;
    if (value.contains('3 bhk') || value.contains('villa')) {
      return Icons.holiday_village_outlined;
    }
    if (value.contains('pg')) return Icons.group_outlined;
    if (value.contains('flat')) return Icons.apartment_outlined;
    if (value == 'all') return Icons.dashboard_customize_outlined;
    return Icons.apartment_outlined;
  }

  bool _matchesRenterCategory(RenterProperty property, String category) {
    if (category == 'All') return true;

    final propertyType = _normalizeText(property.type);
    final title = _normalizeText(property.name);
    final tags = property.tags.map(_normalizeText).join(' ');
    final combined = '$propertyType $title $tags';
    final target = _normalizeText(category);

    if (target.contains('bhk')) {
      return combined.contains(target);
    }

    if (target == 'flat') {
      return combined.contains('flat') || combined.contains('apartment');
    }

    if (target == 'villa') {
      return combined.contains('villa') || combined.contains('house');
    }

    if (target == 'pg') {
      return combined.contains('pg') || combined.contains('paying guest') || combined.contains('hostel');
    }

    return combined.contains(target);
  }

  String _normalizeText(String value) {
    return value.toLowerCase().replaceAll('-', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  double? _extractMonthlyRent(RenterProperty property) {
    if (property.monthlyRent != null && property.monthlyRent! > 0) {
      return property.monthlyRent;
    }

    final matched = RegExp(r'(\d+(?:\.\d+)?)').allMatches(property.price);
    if (matched.isEmpty) {
      return null;
    }

    final value = double.tryParse(matched.first.group(1) ?? '');
    return value != null && value > 0 ? value : null;
  }

  String _formatBudget(double value) {
    if (value >= 1000) {
      return '₹${(value / 1000).toStringAsFixed(0)}k';
    }
    return '₹${value.toStringAsFixed(0)}';
  }

  String _budgetFilterLabel() {
    final hasBudget =
        _selectedMinBudget > _defaultBudgetMin || _selectedMaxBudget < _defaultBudgetMax;
    if (!hasBudget) {
      return 'Any Budget';
    }
    return '${_formatBudget(_selectedMinBudget)} - ${_formatBudget(_selectedMaxBudget)}';
  }

  Future<void> _openBudgetFilterSheet() async {
    var tempMin = _selectedMinBudget;
    var tempMax = _selectedMaxBudget;
    final colorScheme = Theme.of(context).colorScheme;
    final strongText = colorScheme.onSurface;
    final mutedText = colorScheme.onSurfaceVariant;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Budget Filter',
                        style: TextStyle(
                          color: strongText,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempMin = _defaultBudgetMin;
                            tempMax = _defaultBudgetMax;
                          });
                        },
                        child: Text(
                          'Reset',
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatBudget(tempMin)} - ${_formatBudget(tempMax)} / month',
                    style: TextStyle(color: mutedText, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  RangeSlider(
                    values: RangeValues(tempMin, tempMax),
                    min: _defaultBudgetMin,
                    max: _defaultBudgetMax,
                    activeColor: colorScheme.primary,
                    inactiveColor: colorScheme.outlineVariant,
                    labels: RangeLabels(
                      _formatBudget(tempMin),
                      _formatBudget(tempMax),
                    ),
                    onChanged: (values) {
                      setModalState(() {
                        tempMin = values.start;
                        tempMax = values.end;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedMinBudget = tempMin;
                          _selectedMaxBudget = tempMax;
                        });
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Apply Filter',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    SystemChrome.setSystemUIOverlayStyle(
      brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
    );

    final roleAsync = ref.watch(userRoleProvider);
    final role = roleAsync.valueOrNull;

    if (role == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0E7C86)),
          ),
        ),
      );
    }

    final isOwner = role == 'owner';

    return isOwner ? _buildOwnerScreen() : _buildRenterScreen();
  }

  Widget _buildOwnerScreen() {
    final requestsAsync = ref.watch(ownerBookingRequestsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(
            child: requestsAsync.when(
              data: (requests) => _buildStatsStrip(requests),
              loading: () => _buildStatsStrip(const []),
              error: (_, __) => _buildStatsStrip(const []),
            ),
          ),
          SliverToBoxAdapter(child: _buildBannerCarousel()),
          SliverToBoxAdapter(child: _buildSectionHeader()),
          SliverToBoxAdapter(child: _buildFilterChips(isOwner: true)),
          requestsAsync.when(
            data: (requests) {
              final filtered = _applyOwnerFilters(requests);
              if (requests.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    child: Text(
                      'No user booking requests yet.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ),
                );
              }
              if (filtered.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    child: Text(
                      'No requests for selected filter.',
                      style: TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= filtered.length) return null;
                    return _BookingCard(request: filtered[index]);
                  },
                  childCount: filtered.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 32),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0E7C86)),
                  ),
                ),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Text(
                  err.toString().replaceFirst('Exception: ', ''),
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildRenterScreen() {
    final propertiesAsync = ref.watch(renterPopularPropertiesProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          SliverToBoxAdapter(child: _buildRenterBannerCarousel()),
          propertiesAsync.when(
            data: (properties) {
              final filtered = _applyRenterFilters(properties);
              final hasActiveFilters = _renterSearchQuery.trim().isNotEmpty ||
                  _selectedRenterType != 'All' ||
                  _selectedLocation != 'All' ||
                  _selectedMinBudget > _defaultBudgetMin ||
                  _selectedMaxBudget < _defaultBudgetMax;
              final types = <String>{'All', ...properties.map((p) => p.type.trim())}
                  .where((t) => t.isNotEmpty)
                  .toList();
              final categories = _buildRenterCategories(types);

              if (!types.contains(_selectedRenterType)) {
                _selectedRenterType = 'All';
              }

              final selectedCategoryIndex = categories.indexWhere(
                (c) => c.label == _selectedRenterType,
              );

              return SliverList(
                delegate: SliverChildListDelegate([
                  _buildRenterStatsStrip(properties),
                  _buildRenterSectionHeader(),
                  RenterSearchBar(
                    onChanged: (value) => setState(() => _renterSearchQuery = value),
                    onFilterTap: _openBudgetFilterSheet,
                    hintText: 'Search by location, 2BHK, flat, villa...',
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: DropdownButtonFormField<String>(
                      value: _selectedLocation,
                      items: _locationOptions
                          .map(
                            (location) => DropdownMenuItem(
                              value: location,
                              child: Text(location),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => setState(() {
                        _selectedLocation = value ?? 'All';
                      }),
                      decoration: InputDecoration(
                        isDense: true,
                        filled: true,
                        fillColor: colorScheme.surface,
                        labelText: 'Location',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colorScheme.outlineVariant),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  RenterCategoryRow(
                    categories: categories,
                    selected: selectedCategoryIndex < 0 ? 0 : selectedCategoryIndex,
                    onSelect: (i) => setState(() {
                      if (i >= 0 && i < categories.length) {
                        _selectedRenterType = categories[i].label;
                      }
                    }),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Text(
                            _budgetFilterLabel(),
                            style: TextStyle(color: colorScheme.onSurface, fontSize: 11),
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedMinBudget = _defaultBudgetMin;
                              _selectedMaxBudget = _defaultBudgetMax;
                            });
                          },
                          child: const Text(
                            'Clear Budget',
                            style: TextStyle(color: Color(0xFF0E7C86), fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (properties.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'No owner-uploaded properties are visible right now.',
                            style: TextStyle(fontSize: 13),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'If owners already posted properties, run PROPERTY_RENTER_READ_POLICY.sql in Supabase.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No properties match your current filters.',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
                          ),
                          if (hasActiveFilters) ...[
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () {
                                setState(() {
                                  _renterSearchQuery = '';
                                  _selectedRenterType = 'All';
                                  _selectedLocation = 'All';
                                  _selectedMinBudget = _defaultBudgetMin;
                                  _selectedMaxBudget = _defaultBudgetMax;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0E7C86),
                                side: const BorderSide(color: Color(0xFF0E7C86)),
                              ),
                              child: const Text('Reset all filters'),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    ...filtered.map((property) => _RenterPropertyCard(property: property)),
                ]),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 36),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4ECDC4)),
                  ),
                ),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                child: Text(
                  err.toString().replaceFirst('Exception: ', ''),
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ==================== OWNER WIDGETS ====================

  Widget _buildOwnerSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFF6F8FC),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFF4DC), Color(0xFFF6F8FC)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Booking Requests',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Property Owner Dashboard',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFD4A847).withOpacity(0.15),
                  border: Border.all(
                      color: const Color(0xFFD4A847).withOpacity(0.4),
                      width: 1.5),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Color(0xFFD4A847), size: 20),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD4A847), Color(0xFFA07828)],
                  ),
                ),
                child: const Center(
                  child: Text(
                    'OP',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================== RENTER WIDGETS ====================

  Widget _buildRenterSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFFF6F8FC),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE8F9F4), Color(0xFFF6F8FC)],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'My Bookings',
                      style: TextStyle(
                        fontFamily: 'Georgia',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your booking requests & active leases',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4ECDC4).withOpacity(0.15),
                  border: Border.all(
                      color: const Color(0xFF4ECDC4).withOpacity(0.4),
                      width: 1.5),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Color(0xFF4ECDC4), size: 20),
              ),
              const SizedBox(width: 10),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4ECDC4), Color(0xFF2A9D8F)],
                  ),
                ),
                child: const Center(
                  child: Text(
                    'RT',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRenterStatsStrip(List<RenterProperty> properties) {
    final total = properties.length;
    final verified = properties.where((p) => p.isVerified).length;
    final avgRating = total == 0
        ? '0.0'
        : (properties.fold<double>(0, (sum, p) => sum + p.rating) / total)
            .toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          _StatItem(
              label: 'Total', value: '$total', color: const Color(0xFF8B9BFF)),
          _buildDivider(),
          _StatItem(
              label: 'Top Rated',
              value: avgRating,
              color: const Color(0xFF4ECDC4)),
          _buildDivider(),
          _StatItem(
              label: 'Verified',
              value: total == 0 ? '0%' : '${((verified / total) * 100).round()}%',
              color: const Color(0xFF4ECDC4)),
        ],
      ),
    );
  }

  Widget _buildRenterBannerCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        SizedBox(
          height: 152,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: const [
              _BannerCard(
                gradient: [Color(0xFF0D3B2E), Color(0xFF1A6B4A)],
                icon: Icons.verified_user_outlined,
                title: 'Get Verified',
                subtitle: 'Increase acceptance rates\nwith verification badge',
                tag: 'RECOMMENDED',
              ),
              SizedBox(width: 12),
              _BannerCard(
                gradient: [Color(0xFF2D1B69), Color(0xFF6B3FA0)],
                icon: Icons.rate_review_outlined,
                title: 'Build Your Profile',
                subtitle: 'Stand out with reviews\nand recommendations',
                tag: 'TRENDING',
              ),
              SizedBox(width: 12),
              _BannerCard(
                gradient: [Color(0xFF3B1A00), Color(0xFF8B4500)],
                icon: Icons.favorite_outline,
                title: 'Save Properties',
                subtitle: 'Bookmark and track\nyour favorite homes',
                tag: 'NEW',
              ),
              SizedBox(width: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRenterSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Browse Properties',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'Live',
              style: TextStyle(
                color: Color(0xFF4ECDC4),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsStrip(List<BookingRequest> requests) {
    final pending = requests.where((r) => r.status == 'pending').length;
    final accepted = requests.where((r) => r.status == 'accepted').length;
    final total = requests.length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          _StatItem(
              label: 'Total', value: '$total', color: const Color(0xFF8B9BFF)),
          _buildDivider(),
          _StatItem(
              label: 'Pending',
              value: '$pending',
              color: const Color(0xFFFFB547)),
          _buildDivider(),
          _StatItem(
              label: 'Accepted',
              value: '$accepted',
              color: const Color(0xFF4ECDC4)),
          _buildDivider(),
          _StatItem(
              label: 'Occupancy',
              value: '73%',
              color: const Color(0xFFD4A847)),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 30,
      color: Colors.black12,
    );
  }

  Widget _buildBannerCarousel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        SizedBox(
          height: 152,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: const [
              _BannerCard(
                gradient: [Color(0xFF2D1B69), Color(0xFF6B3FA0)],
                icon: Icons.trending_up_rounded,
                title: 'Rent Season',
                subtitle: 'High demand in\nyour area this month',
                tag: 'TRENDING',
              ),
              SizedBox(width: 12),
              _BannerCard(
                gradient: [Color(0xFF0D3B2E), Color(0xFF1A6B4A)],
                icon: Icons.verified_user_outlined,
                title: 'Get Verified',
                subtitle: 'Boost trust &\nattract better tenants',
                tag: 'RECOMMENDED',
              ),
              SizedBox(width: 12),
              _BannerCard(
                gradient: [Color(0xFF3B1A00), Color(0xFF8B4500)],
                icon: Icons.campaign_outlined,
                title: 'Promote Listing',
                subtitle: 'Reach 10x more\nusers today',
                tag: 'OFFER',
              ),
              SizedBox(width: 12),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Requests',
            style: TextStyle(
              fontFamily: 'Georgia',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text(
              'See All',
              style: TextStyle(
                color: Color(0xFFD4A847),
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips({required bool isOwner}) {
    final filters = isOwner ? _filters : _renterFilters;

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final selected = _selectedFilter == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFD4A847)
                    : const Color(0xFFE9EDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? const Color(0xFFD4A847)
                      : Colors.black12,
                ),
              ),
              child: Text(
                filters[index],
                style: TextStyle(
                  color: selected ? Colors.black : Colors.black54,
                  fontWeight:
                      selected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }


}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatItem(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Georgia',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final List<Color> gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final String tag;

  const _BannerCard({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  final BookingRequest request;

  const _BookingCard({required this.request});

  void _openRenterProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _RenterPublicProfileScreen(request: request),
      ),
    );
  }

  Color get _statusColor {
    switch (request.status) {
      case 'pending':
        return const Color(0xFFFFB547);
      case 'accepted':
        return const Color(0xFF4ECDC4);
      case 'declined':
        return const Color(0xFFFF6B6B);
      default:
        return Colors.grey;
    }
  }

  String get _statusLabel {
    switch (request.status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'declined':
        return 'Declined';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final strongText = colorScheme.onSurface;
    final mutedText = colorScheme.onSurfaceVariant;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: request.status == 'pending'
              ? const Color(0xFFD4A847).withOpacity(0.25)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _statusColor.withOpacity(0.6),
                        _statusColor.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(40),
                    onTap: () => _openRenterProfile(context),
                    child: request.tenantImageUrl != null &&
                            request.tenantImageUrl!.trim().isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              request.tenantImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  request.tenantAvatar,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Center(
                            child: Text(
                              request.tenantAvatar,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          InkWell(
                            onTap: () => _openRenterProfile(context),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                              child: Text(
                                request.tenantName,
                                style: TextStyle(
                                  color: strongText,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Stars
                          Row(
                            children: List.generate(
                              request.rating,
                              (i) => const Icon(Icons.star_rounded,
                                  color: Color(0xFFD4A847), size: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'View user profile',
                        style: TextStyle(color: mutedText, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _statusColor.withOpacity(0.4), width: 1),
                  ),
                  child: Text(
                    _statusLabel,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Property info
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2A2000), Color(0xFF3D2E00)],
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: request.propertyImage.trim().isNotEmpty
                      ? Image.network(
                          request.propertyImage,
                          headers: _imageHeadersFor(request.propertyImage),
                          fit: BoxFit.cover,
                          errorBuilder: (_, error, __) {
                            debugPrint('Property image failed: ${request.propertyImage} -> $error');
                            return const Icon(
                              Icons.apartment_rounded,
                              color: Color(0xFFD4A847),
                              size: 24,
                            );
                          },
                        )
                      : const Icon(
                          Icons.apartment_rounded,
                          color: Color(0xFFD4A847),
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.propertyName,
                        style: TextStyle(
                          color: strongText,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined,
                              color: mutedText, size: 11),
                          const SizedBox(width: 2),
                          Text(
                            request.location,
                            style: TextStyle(
                              color: mutedText, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  '₹${(request.rentAmount / 1000).toStringAsFixed(0)}K/mo',
                  style: const TextStyle(
                    color: Color(0xFFD4A847),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Date info row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Row(
              children: [
                _InfoPill(
                    icon: Icons.calendar_today_outlined,
                    label: request.moveInDate),
                const SizedBox(width: 8),
                _InfoPill(
                    icon: Icons.timelapse_outlined, label: request.duration),
                const SizedBox(width: 8),
                _InfoPill(
                    icon: Icons.send_outlined,
                    label: 'Req: ${request.requestDate}'),
              ],
            ),
          ),

          // Message
          if (request.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(
                        color: _statusColor.withOpacity(0.5), width: 2),
                  ),
                ),
                child: Text(
                  '"${request.message}"',
                  style: TextStyle(
                    color: mutedText,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    height: 1.4,
                  ),
                ),
              ),
            ),

          // Action buttons (only for pending)
          if (request.status == 'pending')
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(
                            color: colorScheme.error.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Decline',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Accept Request',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colorScheme.onSurfaceVariant, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _RenterPropertyCard extends ConsumerWidget {
  final RenterProperty property;

  const _RenterPropertyCard({required this.property});

  Future<void> _openRequestForm(
    BuildContext context,
    WidgetRef ref, {
    required String requestType,
  }) async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first to send booking request.')),
      );
      return;
    }

    final ownerId = (property.ownerId ?? '').trim();
    if (ownerId.isEmpty || property.id.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This property cannot be booked right now.')),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final moveInController = TextEditingController();
    final notesController = TextEditingController();

    final shouldSend = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: Text(requestType == 'connect'
                  ? 'Connect with Owner'
                  : 'Book This Property'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        requestType == 'connect'
                            ? 'Share your details to connect with ${property.ownerName}.'
                            : 'Share your details to book ${property.name}.',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final cleaned = (value ?? '').replaceAll(RegExp(r'\s+'), '');
                          if (cleaned.isEmpty) {
                            return 'Phone number is required';
                          }
                          if (cleaned.length < 8) {
                            return 'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email (optional)',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final trimmed = (value ?? '').trim();
                          if (trimmed.isEmpty) return null;
                          final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          return valid.hasMatch(trimmed) ? null : 'Enter a valid email';
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: moveInController,
                        decoration: const InputDecoration(
                          labelText: 'Preferred Move-in Date',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Message / Requirements',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      Navigator.of(dialogContext).pop(true);
                    }
                  },
                  child: Text(requestType == 'connect' ? 'Send' : 'Book'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldSend) {
      return;
    }

    try {
      final existing = await supabase
          .from('booking_requests')
          .select('id, status, request_type')
          .eq('property_id', property.id)
          .eq('renter_id', user.id)
          .inFilter('status', ['pending', 'accepted'])
          .limit(1);

      if (existing is List && existing.isNotEmpty) {
        if (context.mounted) {
          final status = (existing.first['status'] ?? 'pending').toString();
          final info = status == 'accepted'
              ? 'Your request is already accepted for this property.'
              : 'Request already sent. Owner response pending.';
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(content: Text(info)),
            );
        }
        return;
      }

      await supabase.from('booking_requests').insert({
        'property_id': property.id,
        'owner_id': ownerId,
        'renter_id': user.id,
        'requested_price': property.monthlyRent,
        'message': notesController.text.trim(),
        'status': 'pending',
        'request_type': requestType,
        'contact_name': nameController.text.trim(),
        'contact_phone': phoneController.text.trim(),
        'contact_email': emailController.text.trim(),
        'preferred_move_in': moveInController.text.trim(),
      });

      if (context.mounted) {
        try {
          await ref.read(notificationsControllerProvider.notifier).addNotification(
                title: requestType == 'connect'
                    ? 'Owner connection request sent'
                    : 'Booking successful',
                body: requestType == 'connect'
                    ? 'We shared your details for ${property.name}. Expect a reply soon.'
                    : 'Your booking request for ${property.name} was submitted successfully.',
                bookingId: null,
              );
        } catch (_) {}
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                requestType == 'connect'
                    ? 'Connection request sent. Check Notifications for updates.'
                    : 'Booking successful. Check Notifications for updates.',
              ),
            ),
          );
      }
    } on PostgrestException catch (e) {
      final code = (e.code ?? '').toUpperCase();
      final isMissingTable = code == 'PGRST205' || code == '42P01';
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isMissingTable
                  ? 'booking_requests table missing. Run BOOKING_REQUESTS_SCHEMA.sql.'
                  : 'Could not send request: ${e.message}',
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send booking request. Try again.')),
        );
      }
    }
  }

  void _openOwnerProfile(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _OwnerPublicProfileScreen(property: property),
      ),
    );
  }

  String _postedAgo() {
    final postedAt = property.postedAt;
    if (postedAt == null) {
      return 'Recently posted';
    }

    final now = DateTime.now();
    final diff = now.difference(postedAt);
    if (diff.inDays >= 1) {
      return '${diff.inDays}d ago';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours}h ago';
    }
    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m ago';
    }
    return 'Just now';
  }

  String _ownerInitials() {
    final words = property.ownerName
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'OW';
    if (words.length == 1) {
      final name = words.first;
      return name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    }
    return '${words.first[0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final strongText = colorScheme.onSurface;
    final mutedText = colorScheme.onSurfaceVariant;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: property.isVerified
              ? const Color(0xFF4ECDC4).withOpacity(0.25)
              : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 130,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if ((property.imageUrl ?? '').trim().isNotEmpty)
                  Image.network(
                    property.imageUrl!,
                    headers: _imageHeadersFor(property.imageUrl!),
                    fit: BoxFit.cover,
                    errorBuilder: (_, error, __) {
                      debugPrint('Renter card image failed: ${property.imageUrl} -> $error');
                      return const SizedBox.shrink();
                    },
                  ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        property.gradient.first.withOpacity(0.7),
                        property.gradient.last.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                if (property.isVerified)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified, color: Colors.white, size: 10),
                          SizedBox(width: 3),
                          Text(
                            'Verified',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      property.type,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.name,
                  style: TextStyle(
                    color: strongText,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                      color: mutedText, size: 13),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.location,
                        style: TextStyle(color: mutedText, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      property.price,
                      style: const TextStyle(
                        color: Color(0xFF4ECDC4),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      '${property.rating} (${property.reviews})',
                      style: TextStyle(
                        fontSize: 12,
                        color: strongText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: property.tags
                      .take(3)
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(color: strongText, fontSize: 10),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (property.bedrooms != null)
                      _InfoPill(icon: Icons.bed_outlined, label: '${property.bedrooms} BHK'),
                    if (property.bathrooms != null)
                      _InfoPill(icon: Icons.bathtub_outlined, label: '${property.bathrooms} Bath'),
                    if (property.area != null)
                      _InfoPill(
                        icon: Icons.square_foot_outlined,
                        label: '${property.area!.toStringAsFixed(0)} sqft',
                      ),
                    _InfoPill(icon: Icons.access_time_outlined, label: _postedAgo()),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary.withOpacity(0.2),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(40),
                          onTap: () => _openOwnerProfile(context),
                          child: property.ownerImageUrl != null &&
                                  property.ownerImageUrl!.trim().isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    property.ownerImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Center(
                                      child: Text(
                                        _ownerInitials(),
                                        style: TextStyle(
                                          color: colorScheme.onPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _ownerInitials(),
                                    style: TextStyle(
                                      color: colorScheme.onPrimary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: InkWell(
                          onTap: () => _openOwnerProfile(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  property.ownerName,
                                  style: TextStyle(
                                    color: strongText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Owner: ${property.ownerName}',
                                  style: TextStyle(color: mutedText, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 6,
                        children: [
                          TextButton.icon(
                            onPressed: () => _openRequestForm(
                              context,
                              ref,
                              requestType: 'connect',
                            ),
                            icon: const Icon(Icons.call_outlined, size: 14),
                            label: const Text('Connect'),
                            style: TextButton.styleFrom(
                              foregroundColor: colorScheme.primary,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: colorScheme.primary),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => _openRequestForm(
                              context,
                              ref,
                              requestType: 'book',
                            ),
                            icon: const Icon(Icons.book_online_outlined, size: 14),
                            label: const Text('Book'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerPublicProfileScreen extends StatelessWidget {
  final RenterProperty property;

  const _OwnerPublicProfileScreen({required this.property});

  Future<Map<String, dynamic>> _loadPublicOwnerDetails() async {
    final supabase = Supabase.instance.client;
    final ownerId = (property.ownerId ?? '').trim();

    if (ownerId.isEmpty) {
      return {
        'name': property.ownerName,
        'imageUrl': property.ownerImageUrl,
        'listings': 0,
        'verified': 0,
        'avgRating': property.rating,
        'avgRent': property.monthlyRent,
        'types': <String>[property.type],
        'locations': <String>[property.location],
      };
    }

    Map<String, dynamic>? profile;
    try {
      profile = await supabase
          .from('profiles')
          .select('full_name, avatar_url, image_url, profile_image_url, created_at')
          .eq('id', ownerId)
          .maybeSingle();
    } catch (_) {
      profile = null;
    }

    List<dynamic> properties = const [];
    try {
      properties = await supabase
          .from('property')
          .select('budget, verified, safetyscore, propertytype, location')
          .eq('ownerid', ownerId);
    } catch (_) {
      properties = const [];
    }

    final rows = properties.cast<Map<String, dynamic>>();
    final listings = rows.length;
    final verified = rows.where((r) => r['verified'] == true).length;

    final safetyValues = rows
        .map((r) => (r['safetyscore'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    final avgRating = safetyValues.isEmpty
        ? property.rating
        : double.parse(
            (safetyValues.map((v) => 3.5 + (v.clamp(0, 100) / 100) * 1.5).reduce((a, b) => a + b) /
                    safetyValues.length)
                .toStringAsFixed(1),
          );

    final budgets = rows
        .map((r) => (r['budget'] as num?)?.toDouble())
        .whereType<double>()
        .toList();
    final avgRent = budgets.isEmpty
        ? property.monthlyRent
        : budgets.reduce((a, b) => a + b) / budgets.length;

    final types = rows
        .map((r) => (r['propertytype'] ?? '').toString().trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList();

    final locations = rows
        .map((r) => (r['location'] ?? '').toString().trim())
        .where((v) => v.isNotEmpty)
        .toSet()
        .take(4)
        .toList();

    final name = (profile?['full_name'] ?? property.ownerName).toString().trim();
    final imageUrl = (profile?['avatar_url'] ??
            profile?['image_url'] ??
            profile?['profile_image_url'] ??
            property.ownerImageUrl)
        ?.toString()
        .trim();

    final ownerSinceRaw = (profile?['created_at'] ?? '').toString().trim();
    final ownerSince = DateTime.tryParse(ownerSinceRaw);

    return {
      'name': name.isEmpty ? property.ownerName : name,
      'imageUrl': imageUrl,
      'ownerSince': ownerSince,
      'listings': listings,
      'verified': verified,
      'avgRating': avgRating,
      'avgRent': avgRent,
      'types': types,
      'locations': locations,
    };
  }

  String _formatCurrency(double? value) {
    if (value == null || value <= 0) return 'N/A';
    return 'INR ${value.toStringAsFixed(0)}/mo';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Owner Profile'),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadPublicOwnerDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? const <String, dynamic>{};
          final name = (data['name'] ?? property.ownerName).toString();
          final imageUrl = (data['imageUrl'] ?? '').toString();
          final listings = (data['listings'] as int?) ?? 0;
          final verified = (data['verified'] as int?) ?? 0;
          final avgRating = ((data['avgRating'] as num?) ?? property.rating).toDouble();
          final avgRent = (data['avgRent'] as num?)?.toDouble();
          final types = (data['types'] as List?)?.cast<String>() ?? <String>[];
          final locations = (data['locations'] as List?)?.cast<String>() ?? <String>[];
          final ownerSince = data['ownerSince'] as DateTime?;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: colorScheme.primary.withOpacity(0.2),
                      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                      child: imageUrl.isEmpty
                          ? Text(
                              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'O',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ownerSince == null
                                ? 'Registered owner'
                                : 'Owner since ${ownerSince.year}',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _OwnerMetric(label: 'Rating', value: avgRating.toStringAsFixed(1)),
                    _OwnerMetric(label: 'Listings', value: '$listings'),
                    _OwnerMetric(label: 'Verified', value: '$verified'),
                    _OwnerMetric(label: 'Avg Rent', value: _formatCurrency(avgRent)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important Info',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Property Types',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (types.isEmpty ? <String>[property.type] : types)
                          .map(
                            (t) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                t,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Active Locations',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 6),
                    ...(locations.isEmpty ? <String>[property.location] : locations)
                        .map(
                          (loc) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '• $loc',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                    const SizedBox(height: 10),
                    Text(
                      'Sensitive details like phone/email are hidden on this public profile. Use Connect button on card to request contact.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OwnerMetric extends StatelessWidget {
  final String label;
  final String value;

  const _OwnerMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RenterPublicProfileScreen extends StatelessWidget {
  final BookingRequest request;

  const _RenterPublicProfileScreen({required this.request});

  Future<Map<String, dynamic>> _loadPublicRenterDetails() async {
    final supabase = Supabase.instance.client;
    final renterId = (request.renterId ?? '').trim();

    if (renterId.isEmpty) {
      return {
        'name': request.tenantName,
        'imageUrl': request.tenantImageUrl,
        'city': request.renterCity,
        'renterType': request.renterType,
        'budget': request.renterBudget,
        'memberSince': request.renterCreatedAt,
        'totalRequests': 0,
        'acceptedRequests': 0,
      };
    }

    Map<String, dynamic>? profile;
    try {
      profile = await supabase
          .from('profiles')
          .select('full_name, name, avatar_url, image_url, profile_image_url, city, renter_type, budget, created_at')
          .eq('id', renterId)
          .maybeSingle();
    } catch (_) {
      profile = null;
    }

    List<dynamic> requests = const [];
    try {
      requests = await supabase
          .from('booking_requests')
          .select('status')
          .eq('renter_id', renterId);
    } catch (_) {
      requests = const [];
    }

    final reqRows = requests.cast<Map<String, dynamic>>();
    final totalRequests = reqRows.length;
    final acceptedRequests = reqRows
        .where((row) => (row['status'] ?? '').toString().toLowerCase() == 'accepted')
        .length;

    final name = (profile?['full_name'] ?? profile?['name'] ?? request.tenantName)
        .toString()
        .trim();
    final imageUrl = (profile?['avatar_url'] ??
            profile?['image_url'] ??
            profile?['profile_image_url'] ??
            request.tenantImageUrl)
        ?.toString()
        .trim();

    return {
      'name': name.isEmpty ? request.tenantName : name,
      'imageUrl': imageUrl,
      'city': (profile?['city'] ?? request.renterCity)?.toString(),
      'renterType': (profile?['renter_type'] ?? request.renterType)?.toString(),
      'budget': (profile?['budget'] ?? request.renterBudget)?.toString(),
      'memberSince': DateTime.tryParse((profile?['created_at'] ?? '').toString()) ??
          request.renterCreatedAt,
      'totalRequests': totalRequests,
      'acceptedRequests': acceptedRequests,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('User Profile'),
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadPublicRenterDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? const <String, dynamic>{};
          final name = (data['name'] ?? request.tenantName).toString();
          final imageUrl = (data['imageUrl'] ?? '').toString();
          final city = (data['city'] ?? 'Not shared').toString();
          final renterType = (data['renterType'] ?? 'Not specified').toString();
          final budget = (data['budget'] ?? 'Not specified').toString();
          final memberSince = data['memberSince'] as DateTime?;
          final totalRequests = (data['totalRequests'] as int?) ?? 0;
          final acceptedRequests = (data['acceptedRequests'] as int?) ?? 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: colorScheme.primary.withOpacity(0.15),
                      backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                      child: imageUrl.isEmpty
                          ? Text(
                              name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'R',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            memberSince == null
                              ? 'User member'
                                : 'Member since ${memberSince.year}',
                            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _OwnerMetric(label: 'Requests', value: '$totalRequests'),
                    _OwnerMetric(label: 'Accepted', value: '$acceptedRequests'),
                    _OwnerMetric(label: 'City', value: city),
                    _OwnerMetric(label: 'Budget', value: budget),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Important Info',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'User Type: $renterType',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Preferred City: $city',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Budget Preference: $budget',
                      style: TextStyle(fontSize: 12, color: colorScheme.onSurface),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Sensitive details like phone and email are intentionally hidden in this public profile.',
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

String _extractPropertyImage(Map<String, dynamic>? property) {
  if (property == null) return '';

  final dynamic raw = property['images'] ?? property['image'] ?? property['image_url'];
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

Map<String, String> _imageHeadersFor(String url) {
  final uri = Uri.tryParse(url);
  final referer = (uri != null && uri.hasScheme && uri.hasAuthority)
      ? '${uri.scheme}://${uri.authority}/'
      : 'https://google.com/';

  return {
    'User-Agent':
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Mobile Safari/537.36',
    'Accept': 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
    'Referer': referer,
  };
}