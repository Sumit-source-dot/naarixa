import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/complaint.dart';
import '../../domain/repositories/complaint_repository.dart';
import '../models/complaint_model.dart';

class ComplaintRepositoryImpl implements ComplaintRepository {
  final SupabaseClient _client = SupabaseService.client;

  @override
  Future<List<Complaint>> fetchComplaints() async {
    final user = _client.auth.currentUser;
    if (user == null) return const [];

    final rows = await _client
        .from('complaints')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return rows.map<Complaint>((row) => ComplaintModel.fromMap(row)).toList();
  }

  @override
  Future<void> submitComplaint(Complaint complaint) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Please login to submit a complaint.');
    }

    final payload = ComplaintModel(
      id: complaint.id,
      title: complaint.title,
      description: complaint.description,
      priority: complaint.priority,
      status: complaint.status,
      createdAt: complaint.createdAt,
    ).toInsertMap(user.id);

    await _client.from('complaints').insert(payload);
  }

  @override
  Future<void> deleteComplaint(String complaintId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const AuthException('Please login to delete a complaint.');
    }

    await _client
        .from('complaints')
        .delete()
        .eq('id', complaintId)
        .eq('user_id', user.id);
  }
}