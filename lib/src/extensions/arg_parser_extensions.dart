import 'package:args/args.dart';

extension ArgParserExtensions on ArgParser {
  /// Adds a 'verbose' flag to the parser.
  void addVerboseFlag() {
    addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help:
          'Print debug information. '
          'Can be used with any command.',
    );
  }
}
