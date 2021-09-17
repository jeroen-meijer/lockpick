import 'package:lockpick/src/functions/functions.dart';

/// TODO: Document this.
enum DependencyType { main, dev }

extension NullableDependencyTypeExtensions on DependencyType? {
  /// Returns a description of this [DependencyType].
  String describe() => describeEnum(this);
}
