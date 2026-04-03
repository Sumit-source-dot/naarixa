class PaginatedResponse<T> {
  const PaginatedResponse({required this.items, required this.page, required this.total});

  final List<T> items;
  final int page;
  final int total;
}