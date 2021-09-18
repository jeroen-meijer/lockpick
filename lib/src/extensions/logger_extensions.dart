import 'dart:io';

import 'package:io/ansi.dart';
import 'package:mason/mason.dart';

extension LoggerExtensions on Logger {
  static bool isVerboseEnabled = false;

  /// Writes debug message to stdout.
  void debug(String? message) {
    if (isVerboseEnabled) {
      stdout.writeln(lightGray.wrap(message));
    }
  }
}
