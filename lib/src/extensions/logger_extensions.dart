import 'dart:io';

import 'package:io/ansi.dart';
import 'package:mason/mason.dart';

extension LoggerExtensions on Logger {
  /// Writes debug message to stdout.
  void debug(String? message) => stdout.writeln(lightGray.wrap(message));
}
