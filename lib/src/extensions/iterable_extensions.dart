import 'package:lockpick/src/functions/functions.dart' as f;

extension IterableExtensions<T> on Iterable<T> {
  /// Finds the first [DependencyType] of which the description matches
  /// the given [value].
  T findEnumValue(String value) => f.findEnumValue(this, value);
}
