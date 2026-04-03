import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/safest_route_provider.dart';

class SafestRouteScreen extends ConsumerStatefulWidget {
  const SafestRouteScreen({super.key});

  @override
  ConsumerState<SafestRouteScreen> createState() => _SafestRouteScreenState();
}

class _SafestRouteScreenState extends ConsumerState<SafestRouteScreen> {
  SafetyRouteType _selectedMode = SafetyRouteType.fastest;

  @override
  Widget build(BuildContext context) {
    final cities = ref.watch(availableCitiesProvider);
    final query = ref.watch(routeQueryProvider);
    final result = ref.watch(routeComparisonProvider);

    final activeRoute = result == null
        ? null
        : _selectedMode == SafetyRouteType.fastest
        ? result.fastestRoute
        : result.safestRoute;

    return Scaffold(
      appBar: AppBar(title: const Text('Punjab Route Planner')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Source & Destination',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: cities.contains(query.from) ? query.from : null,
                    decoration: const InputDecoration(labelText: 'From'),
                    items: cities
                        .map(
                          (city) =>
                              DropdownMenuItem(value: city, child: Text(city)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      ref.read(routeQueryProvider.notifier).state = RouteQuery(
                        from: value,
                        to: query.to,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: cities.contains(query.to) ? query.to : null,
                    decoration: const InputDecoration(labelText: 'To'),
                    items: cities
                        .map(
                          (city) =>
                              DropdownMenuItem(value: city, child: Text(city)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      ref.read(routeQueryProvider.notifier).state = RouteQuery(
                        from: query.from,
                        to: value,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: query.from == query.to
                          ? null
                          : () {
                              ref.invalidate(routeComparisonProvider);
                            },
                      child: const Text('Find Route'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (query.from == query.to)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Text('Choose different From and To cities.'),
              ),
            ),
          if (activeRoute != null) ...[
            _JourneySummaryCard(
              query: query,
              route: activeRoute,
              selectedMode: _selectedMode,
              onModeChanged: (mode) {
                setState(() => _selectedMode = mode);
              },
            ),
            const SizedBox(height: 10),
            _TimelineCard(route: activeRoute),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🚨 Safety Alerts',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    ...result!.alerts.map(
                      (alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('• $alert'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JourneySummaryCard extends StatelessWidget {
  const _JourneySummaryCard({
    required this.query,
    required this.route,
    required this.selectedMode,
    required this.onModeChanged,
  });

  final RouteQuery query;
  final RouteResult route;
  final SafetyRouteType selectedMode;
  final ValueChanged<SafetyRouteType> onModeChanged;

  @override
  Widget build(BuildContext context) {
    final fare = route.estimatedFare;
    final stations = route.segments.length + 1; // Number of stops
    final durationMinutes = route.etaMinutes;
    final now = DateTime.now();
    final end = now.add(Duration(minutes: durationMinutes));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${query.from} → ${query.to}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _ModeButton(
                    label: 'Shortest Route',
                    active: selectedMode == SafetyRouteType.fastest,
                    onTap: () => onModeChanged(SafetyRouteType.fastest),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeButton(
                    label: 'Safest Route',
                    active: selectedMode == SafetyRouteType.safest,
                    onTap: () => onModeChanged(SafetyRouteType.safest),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.lightBlue.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_formatTime(now)} - ${_formatTime(end)}'),
                  Text(
                    _formatDuration(durationMinutes),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Fare: ₹ $fare',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    'Stations: $stations',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Safety Score: ${route.averageSafety.toStringAsFixed(1)} • Risk: ${route.riskLevel}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDuration(int totalMinutes) {
    if (totalMinutes < 60) {
      return '$totalMinutes mins';
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes} mins';
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: active ? Colors.red : colorScheme.surfaceVariant,
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.route});

  final RouteResult route;

  @override
  Widget build(BuildContext context) {
    if (route.path.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Route Timeline',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            ...List.generate(route.path.length, (index) {
              final city = route.path[index];
              final isLast = index == route.path.length - 1;
              final markerColor = _markerColor(index, route);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: markerColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 30,
                            color: markerColor.withValues(alpha: 0.5),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            city,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!isLast)
                            Text(
                              _segmentHint(route, index),
                              style: TextStyle(color: colorScheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Color _markerColor(int index, RouteResult route) {
    if (index >= route.segments.length) {
      return Colors.green;
    }
    final riskLevel = route.segments[index].riskLevel;
    return switch (riskLevel) {
      RoadRiskLevel.low => Colors.green,
      RoadRiskLevel.medium => Colors.orange,
      RoadRiskLevel.high => Colors.red,
    };
  }

  String _segmentHint(RouteResult route, int index) {
    if (index >= route.segments.length) return '';
    final segment = route.segments[index];
    return 'Next: ${segment.distance.toStringAsFixed(0)} km • Safety ${segment.safetyScore.toStringAsFixed(1)}';
  }
}