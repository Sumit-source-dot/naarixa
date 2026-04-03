import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  Env._();

  static String? _optional(String key) {
    final value = dotenv.env[key];
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  static String get supabaseUrl {
    final value = dotenv.env['SUPABASE_URL'];
    if (value == null || value.isEmpty) {
      throw StateError('SUPABASE_URL is missing in .env');
    }
    return value;
  }

  static String get supabaseAnonKey {
    final value = dotenv.env['SUPABASE_ANON_KEY'];
    if (value == null || value.isEmpty) {
      throw StateError('SUPABASE_ANON_KEY is missing in .env');
    }
    return value;
  }

  static String get safetyReportsTable {
    return _optional('SAFETY_REPORTS_TABLE') ?? 'safety_reports';
  }

  static String? get crimeDataApiUrl => _optional('CRIME_DATA_API_URL');

  static String? get safePlacesApiUrl => _optional('SAFE_PLACES_API_URL');

  static String? get crowdDensityApiUrl => _optional('CROWD_DENSITY_API_URL');
}
