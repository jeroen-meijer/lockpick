import 'package:lockpick/src/functions/functions.dart';

/// The type/flavor of a dependency.
///
/// Can either be [main] (for `dependencies`) or [dev] (for `dev_dependencies`).
///
/// See also:
/// * [getPubspecName], which return the approach pubspec-compatible name for a
///   [DependencyType].
enum DependencyType { main, dev }

extension NullableDependencyTypeExtensions on DependencyType? {
  /// Returns a description of this [DependencyType].
  String describe() => describeEnum(this);

  /// Returns the pubspec name for this [DependencyType].
  ///
  /// main: `"dependencies"`
  /// dev: `"dev_dependencies"`
  String getPubspecName() {
    switch (this) {
      case DependencyType.dev:
        return 'dev_dependencies';
      case DependencyType.main:
      default:
        return 'dependencies';
    }
  }
}
