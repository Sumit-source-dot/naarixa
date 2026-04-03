import '../entities/complaint.dart';

abstract class ComplaintRepository {
  Future<void> submitComplaint(Complaint complaint);
  Future<List<Complaint>> fetchComplaints();
  Future<void> deleteComplaint(String complaintId);
}