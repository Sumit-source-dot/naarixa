import '../../domain/entities/complaint.dart';

class ComplaintModel extends Complaint {
  const ComplaintModel({
    required super.id,
    required super.title,
    required super.description,
    required super.priority,
    required super.status,
    required super.createdAt,
  });

  factory ComplaintModel.fromMap(Map<String, dynamic> map) {
    return ComplaintModel(
      id: map['id']?.toString() ?? '',
      title: (map['title'] as String?)?.trim() ?? 'Complaint',
      description: (map['description'] as String?)?.trim() ?? '',
      priority: (map['priority'] as String?)?.trim() ?? 'medium',
      status: (map['status'] as String?)?.trim() ?? 'open',
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toInsertMap(String userId) {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
    };
  }
}