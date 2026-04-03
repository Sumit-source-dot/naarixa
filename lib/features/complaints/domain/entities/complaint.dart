class Complaint {
  const Complaint({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String priority;
  final String status;
  final DateTime createdAt;
}