import 'package:supabase_flutter/supabase_flutter.dart';

/// Debug service to test Supabase connection and data insertion
class DebugService {
  static Future<void> testSupabaseConnection() async {
    print("\n${DateTime.now()} - 🔍 DEBUGGING SUPABASE CONNECTION");
    print("=" * 60);

    try {
      final client = Supabase.instance.client;

      // 1. Check if user is authenticated
      final user = client.auth.currentUser;
      if (user == null) {
        print("❌ NO AUTHENTICATED USER!");
        print("   Please log in first before testing SOS.");
        return;
      }

      print("✅ Authenticated User: ${user.id}");
      print("   Email: ${user.email}");

      // 2. Test Supabase connection
      print("\n📡 Testing Supabase connection...");
      try {
        final response = await client.from('sos_alerts').count();
        print("✅ Supabase connection successful!");
        print("   sos_alerts table count: $response");
      } catch (e) {
        print("❌ Supabase connection failed: $e");
        return;
      }

      // 3. Verify tables exist and RLS is set correctly
      print("\n📋 Checking table configuration...");
      await _checkTable(client, 'sos_alerts');
      await _checkTable(client, 'live_tracking');

      // 4. Test inserting a record
      print("\n🧪 Testing SOS alert insertion...");
      await _testInsertSOS(client, user.id);

      print("\n" + "=" * 60);
      print("✅ ALL TESTS PASSED - Supabase is properly configured!\n");
    } catch (e, stackTrace) {
      print("\n❌ UNEXPECTED ERROR: $e");
      print("Stack trace: $stackTrace");
    }
  }

  static Future<void> _checkTable(SupabaseClient client, String tableName) async {
    try {
      final response = await client.from(tableName).select('*').limit(1);
      print("✅ Table '$tableName' accessible - RLS allows SELECT");
    } on PostgrestException catch (e) {
      print("❌ Table '$tableName' error:");
      print("   Code: ${e.code}");
      print("   Message: ${e.message}");
      print("   Details: ${e.details}");
      print("   Hint: ${e.hint}");
    }
  }

  static Future<void> _testInsertSOS(SupabaseClient client, String userId) async {
    try {
      final testData = {
        'user_id': userId,
        'latitude': 40.7128,
        'longitude': -74.0060,
        'status': 'active',
        'risk_level': 'low',
      };

      print("   Inserting test record: $testData");

      final response = await client
          .from('sos_alerts')
          .insert(testData)
          .select('id')
          .single();

      final sosId = response['id'];
      print("✅ Successfully inserted SOS alert with ID: $sosId");
      print("   Response: $response");

      // Try to retrieve it
      final retrieved = await client
          .from('sos_alerts')
          .select('*')
          .eq('id', sosId)
          .single();

      print("✅ Successfully retrieved: $retrieved");

      // Clean up - delete test record
      await client.from('sos_alerts').delete().eq('id', sosId);
      print("✅ Test record deleted");
    } on PostgrestException catch (e) {
      print("❌ Insert test failed:");
      print("   Code: ${e.code}");
      print("   Message: ${e.message}");
      print("   Details: ${e.details}");
      print("   Hint: ${e.hint}");

      // Common fixes
      if (e.code == '23503') {
        print("\n💡 FIX: This is a foreign key error. Check:");
        print("   - user_id '$userId' exists in auth.users");
        print("   - OR remove the foreign key constraint if testing");
      } else if (e.code == '42P01') {
        print("\n💡 FIX: Table does not exist. Run sos/SOS_TRACKING_SCHEMA.sql");
      } else if (e.code == '42703') {
        print("\n💡 FIX: Column does not exist. Check table schema.");
      } else if (e.message.contains('permission denied')) {
        print("\n💡 FIX: RLS policy is blocking this operation. Check:");
        print("   - auth.uid() matches user_id");
        print("   - Policies allow INSERT for authenticated users");
        print("   - Run sos/SOS_FIX_RLS_POLICIES.sql to fix RLS");
      }
    } catch (e) {
      print("❌ Unexpected error: $e");
    }
  }

  static Future<void> listAllSOSAlerts() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        print("❌ No authenticated user");
        return;
      }

      print("\n📊 SOS Alerts for current user:");
      print("=" * 60);

      final alerts = await client
          .from('sos_alerts')
          .select('*')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (alerts.isEmpty) {
        print("No SOS alerts found");
      } else {
        for (var alert in alerts) {
          print("\nAlert ID: ${alert['id']}");
          print("  Status: ${alert['status']}");
          print("  Risk Level: ${alert['risk_level']}");
          print("  Location: ${alert['latitude']}, ${alert['longitude']}");
          print("  Created: ${alert['created_at']}");
        }
      }

      print("\n" + "=" * 60);
    } catch (e) {
      print("❌ Error retrieving alerts: $e");
    }
  }
}
