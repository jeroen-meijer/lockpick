extension StringExtensions on String {
  /// Returns this string if the string is not empty, otherwise returns [other].
  String orIfEmpty(String other) {
    return isEmpty ? other : this;
  }
}
