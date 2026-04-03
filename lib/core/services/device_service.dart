import 'supabase_service.dart';

class DeviceService {
  Future<List<Map<String, dynamic>>> fetchDevices() async {
    final response = await SupabaseService.client.from('devices').select();
    return List<Map<String, dynamic>>.from(response);
  }
}
