import 'package:lockpick/src/functions/functions.dart';

/// TODO: Document this.
enum CaretSyntaxPreference { auto, always, never }

extension NullableCaretSyntaxPreferenceExtensions on CaretSyntaxPreference? {
  /// Returns a description of this [CaretSyntaxPreference].
  String describe() => describeEnum(this);
}
