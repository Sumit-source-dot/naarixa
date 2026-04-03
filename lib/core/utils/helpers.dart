class Helpers {
  Helpers._();

  static bool isNullOrEmpty(String? value) =>
      value == null || value.trim().isEmpty;
}
