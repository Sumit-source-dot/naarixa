import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/complaint_repository_impl.dart';
import '../../domain/entities/complaint.dart';
import '../../domain/repositories/complaint_repository.dart';

final complaintPriorityFilterProvider = StateProvider<String>((ref) => 'all');

final complaintRepositoryProvider = Provider<ComplaintRepository>(
  (ref) => ComplaintRepositoryImpl(),
);

final complaintsControllerProvider = StateNotifierProvider<ComplaintsController, AsyncValue<List<Complaint>>>(
  (ref) => ComplaintsController(ref.read(complaintRepositoryProvider)),
);

class ComplaintsController extends StateNotifier<AsyncValue<List<Complaint>>> {
  ComplaintsController(this._repository) : super(const AsyncValue.loading()) {
    _loadComplaints();
  }

  final ComplaintRepository _repository;

  Future<void> _loadComplaints() async {
    try {
      final items = await _repository.fetchComplaints();
      state = AsyncValue.data(items);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadComplaints();
  }

  Future<void> submitComplaint({
    required String title,
    required String description,
    required String priority,
  }) async {
    final complaint = Complaint(
      id: '',
      title: title,
      description: description,
      priority: priority,
      status: 'open',
      createdAt: DateTime.now(),
    );

    await _repository.submitComplaint(complaint);
    await _loadComplaints();
  }

  Future<void> deleteComplaint(String complaintId) async {
    final currentState = state;

    state = currentState.whenData(
      (items) => items
          .where((item) => item.id != complaintId)
          .toList(growable: false),
    );

    try {
      await _repository.deleteComplaint(complaintId);
    } catch (error, stackTrace) {
      state = currentState;
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }
}