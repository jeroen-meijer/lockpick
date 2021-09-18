import 'package:args/command_runner.dart';

extension CommandExtensions<T> on Command<T> {
  /// Indicates if the verbose flag was set.
  bool get isVerboseFlagSet => argResults!['verbose'] == true;
}
