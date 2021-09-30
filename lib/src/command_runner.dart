import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:io/ansi.dart';
import 'package:io/io.dart';
import 'package:lockpick/src/commands/commands.dart';
import 'package:lockpick/src/extensions/extensions.dart';
import 'package:lockpick/src/logger.dart';
import 'package:lockpick/src/version.dart';

/// {@template lockpick_command_runner}
/// A CLI for syncing Dart dependency versions between pubspec.yaml and
/// pubspec.lock files.
/// {@endtemplate}
class LockpickCommandRunner extends CommandRunner<int> {
  /// {@macro lockpick_command_runner}
  LockpickCommandRunner({
    Logger? logger,
  })  : _logger = logger ?? Logger(),
        super(
          'lockpick',
          'A CLI for syncing Dart dependency versions '
              'between pubspec.yaml and pubspec.lock files. 🔒',
        ) {
    argParser
      ..addFlag(
        'version',
        negatable: false,
        help: 'Print the current version of lockpick.',
      )
      ..addVerboseFlag();
    addCommand(SyncCommand(logger: logger));
  }

  /// Standard timeout duration for the CLI.
  static const timeout = Duration(milliseconds: 500);

  final Logger _logger;

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      if (args.isEmpty) {
        throw UsageException('No command specified.', '');
      } else {
        return await runCommand(parse(args)) ?? ExitCode.success.code;
      }
    } on FormatException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } on UsageException catch (e) {
      _logger
        ..err(e.message)
        ..info('')
        ..info(usage);
      return ExitCode.usage.code;
    } catch (e, st) {
      _logger
        ..err(styleBold.wrap('Unexpected error occurred'))
        ..err(e.toString())
        ..err(lightGray.wrap(st.toString()));
      return ExitCode.software.code;
    }
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    if (topLevelResults['version'] == true) {
      _logger.info('lockpick version: $packageVersion');
      return ExitCode.success.code;
    } else {
      final exitCode = await super.runCommand(topLevelResults);
      if (exitCode == ExitCode.success.code) {
        _logger.success('Done!');
      }
      return exitCode;
    }
  }
}
