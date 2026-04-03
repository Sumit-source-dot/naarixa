import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SafetyRouteType { safest, fastest }

class RouteQuery {
  const RouteQuery({required this.from, required this.to});

  final String from;
  final String to;

  bool get isValid => from.trim().isNotEmpty && to.trim().isNotEmpty;
}

class RoadSegment {
  const RoadSegment({
    required this.from,
    required this.to,
    required this.distance,
    required this.crime,
    required this.lighting,
    required this.police,
    required this.crowd,
  });

  final String from;
  final String to;
  final double distance;

  /// Realistic scaled values (0–10)
  final double crime;
  final int lighting;
  final int police;
  final int crowd;

  double get safetyScore => calculateSafety(this);

  RoadRiskLevel get riskLevel {
    if (safetyScore >= 7.5) return RoadRiskLevel.low;
    if (safetyScore >= 5.5) return RoadRiskLevel.medium;
    return RoadRiskLevel.high;
  }

  bool touches(String cityA, String cityB) {
    return (from == cityA && to == cityB) || (from == cityB && to == cityA);
  }
}

enum RoadRiskLevel { low, medium, high }

class RouteResult {
  const RouteResult({
    required this.type,
    required this.path,
    required this.segments,
    required this.totalDistance,
    required this.averageSafety,
    required this.riskLevel,
    required this.estimatedFare,
    required this.etaMinutes,
  });

  final SafetyRouteType type;
  final List<String> path;
  final List<RoadSegment> segments;
  final double totalDistance;
  final double averageSafety;
  final String riskLevel;

  /// NEW REAL DATA
  final int estimatedFare;
  final int etaMinutes;

  String get pathLabel => path.join(' → ');
}

class RouteComparisonResult {
  const RouteComparisonResult({
    required this.query,
    required this.safestRoute,
    required this.fastestRoute,
    required this.alerts,
    required this.riskyAreas,
  });

  final RouteQuery query;
  final RouteResult safestRoute;
  final RouteResult fastestRoute;
  final List<String> alerts;
  final List<RoadSegment> riskyAreas;
}

const List<Map<String, dynamic>> routeGraphData = [
  {
    'from': 'Chandigarh',
    'to': 'Mohali',
    'distance': 10,
    'crime': 2.5,
    'lighting': 9,
    'police': 8,
    'crowd': 8,
  },
  {
    'from': 'Mohali',
    'to': 'Kharar',
    'distance': 8,
    'crime': 3.5,
    'lighting': 7,
    'police': 6,
    'crowd': 6,
  },
  {
    'from': 'Kharar',
    'to': 'Ludhiana',
    'distance': 90,
    'crime': 5.0,
    'lighting': 5,
    'police': 5,
    'crowd': 5,
  },
  {
    'from': 'Chandigarh',
    'to': 'Patiala',
    'distance': 70,
    'crime': 3.2,
    'lighting': 7,
    'police': 7,
    'crowd': 7,
  },
  {
    'from': 'Patiala',
    'to': 'Ludhiana',
    'distance': 60,
    'crime': 4.8,
    'lighting': 6,
    'police': 5,
    'crowd': 6,
  },
  {
    'from': 'Ludhiana',
    'to': 'Jalandhar',
    'distance': 60,
    'crime': 4.5,
    'lighting': 7,
    'police': 6,
    'crowd': 8,
  },
  {
    'from': 'Jalandhar',
    'to': 'Amritsar',
    'distance': 80,
    'crime': 3.0,
    'lighting': 8,
    'police': 7,
    'crowd': 8,
  },
  {
    'from': 'Ludhiana',
    'to': 'Bathinda',
    'distance': 110,
    'crime': 5.5,
    'lighting': 4,
    'police': 4,
    'crowd': 4,
  },
  {
    'from': 'Amritsar',
    'to': 'Pathankot',
    'distance': 110,
    'crime': 3.2,
    'lighting': 7,
    'police': 6,
    'crowd': 6,
  },
];
const List<String> punjabCities = [
  'Chandigarh',
  'Mohali',
  'Kharar',
  'Ludhiana',
  'Patiala',
  'Jalandhar',
  'Amritsar',
  'Bathinda',
  'Pathankot',
];

/// ✅ IMPROVED SAFETY FORMULA
double calculateSafety(RoadSegment route) {
  return (10 - route.crime) * 0.4 +
      route.lighting * 0.2 +
      route.police * 0.2 +
      route.crowd * 0.2;
}

final availableCitiesProvider = Provider<List<String>>((ref) => punjabCities);

final routeQueryProvider = StateProvider<RouteQuery>((ref) {
  return const RouteQuery(from: 'Chandigarh', to: 'Amritsar');
});

final routeComparisonProvider = Provider<RouteComparisonResult?>((ref) {
  final query = ref.watch(routeQueryProvider);
  if (!query.isValid || query.from == query.to) {
    return null;
  }

  final planner = _RoutePlanner(routeGraphData);
  return planner.compare(query: query);
});

class _RoutePlanner {
  _RoutePlanner(List<Map<String, dynamic>> graphData)
    : segments = graphData
          .map(
            (raw) => RoadSegment(
              from: raw['from'],
              to: raw['to'],
              distance: (raw['distance'] as num).toDouble(),
              crime: (raw['crime'] as num).toDouble(),
              lighting: raw['lighting'],
              police: raw['police'],
              crowd: raw['crowd'],
            ),
          )
          .toList();

  final List<RoadSegment> segments;

  RouteComparisonResult compare({required RouteQuery query}) {
    final safestPath = _dijkstra(
      source: query.from,
      target: query.to,
      weight: (edge) => (10 - edge.safetyScore),
    );

    final fastestPath = _dijkstra(
      source: query.from,
      target: query.to,
      weight: (edge) => edge.distance,
    );

    final safestRoute = _buildRouteResult(
      type: SafetyRouteType.safest,
      path: safestPath,
    );

    final fastestRoute = _buildRouteResult(
      type: SafetyRouteType.fastest,
      path: fastestPath,
    );

    final alerts = _buildAlerts(safestRoute, fastestRoute);

    final riskyAreas = segments
        .where((s) => s.riskLevel == RoadRiskLevel.high)
        .toList();

    return RouteComparisonResult(
      query: query,
      safestRoute: safestRoute,
      fastestRoute: fastestRoute,
      alerts: alerts,
      riskyAreas: riskyAreas,
    );
  }

  List<String> _dijkstra({
    required String source,
    required String target,
    required double Function(RoadSegment edge) weight,
  }) {
    final nodes = {
      for (final s in segments) s.from,
      for (final s in segments) s.to,
    };

    final distances = {for (var n in nodes) n: double.infinity};
    final previous = <String, String?>{for (var n in nodes) n: null};

    distances[source] = 0;

    final unvisited = {...nodes};

    while (unvisited.isNotEmpty) {
      final current = unvisited.reduce(
        (a, b) => distances[a]! < distances[b]! ? a : b,
      );

      if (current == target) break;

      unvisited.remove(current);

      for (final edge in _connectedEdges(current)) {
        final neighbor = edge.from == current ? edge.to : edge.from;

        if (!unvisited.contains(neighbor)) continue;

        final newDist = distances[current]! + weight(edge);

        if (newDist < distances[neighbor]!) {
          distances[neighbor] = newDist;
          previous[neighbor] = current;
        }
      }
    }

    final path = <String>[];
    String? step = target;

    while (step != null) {
      path.insert(0, step);
      step = previous[step];
    }

    return path.first == source ? path : [];
  }

  Iterable<RoadSegment> _connectedEdges(String city) {
    return segments.where((s) => s.from == city || s.to == city);
  }

  RouteResult _buildRouteResult({
    required SafetyRouteType type,
    required List<String> path,
  }) {
    final pathSegments = <RoadSegment>[];

    for (int i = 0; i < path.length - 1; i++) {
      final segment = segments.firstWhere(
        (s) => s.touches(path[i], path[i + 1]),
      );
      pathSegments.add(segment);
    }

    final totalDistance = pathSegments.fold(0.0, (sum, s) => sum + s.distance);

    final avgSafety = pathSegments.isEmpty
        ? 0.0
        : pathSegments.map((s) => s.safetyScore).reduce((a, b) => a + b) /
              pathSegments.length;

    final fare = realFare(totalDistance);
    final eta = calculateETA(totalDistance);

    return RouteResult(
      type: type,
      path: path,
      segments: pathSegments,
      totalDistance: totalDistance,
      averageSafety: avgSafety,
      riskLevel: _riskLabel(avgSafety),
      estimatedFare: fare,
      etaMinutes: eta,
    );
  }

  List<String> _buildAlerts(RouteResult safest, RouteResult fastest) {
    final alerts = <String>{};

    for (final s in [...safest.segments, ...fastest.segments]) {
      if (s.crime >= 6) {
        alerts.add("${s.from} → ${s.to}: High crime");
      }
      if (s.lighting <= 5) {
        alerts.add("${s.from} → ${s.to}: Poor lighting");
      }
    }

    return alerts.isEmpty ? ["No major risks detected"] : alerts.toList();
  }

  String _riskLabel(double safety) {
    if (safety >= 7.5) return 'Low';
    if (safety >= 5.5) return 'Medium';
    return 'High';
  }
}

/// ✅ REAL FARE (₹)
int realFare(double distanceKm) {
  const ratePerKm = 12; // realistic intercity
  return (distanceKm * ratePerKm).round();
}

/// ✅ REALISTIC ETA
int calculateETA(double distanceKm) {
  const speed = 55.0;
  return ((distanceKm / speed) * 60).round();
}
