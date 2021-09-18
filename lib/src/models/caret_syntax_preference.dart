import 'package:lockpick/src/functions/functions.dart';

/// The preference for using caret syntax (^) for dependency versions.
///
/// * [auto]: Automatically detect if a pubspec is using caret syntax.
/// * [always]: Always use caret syntax.
/// * [never]: Never use caret syntax.
enum CaretSyntaxPreference { auto, always, never }

extension NullableCaretSyntaxPreferenceExtensions on CaretSyntaxPreference? {
  /// Returns a description of this [CaretSyntaxPreference].
  String describe() => describeEnum(this);
}
