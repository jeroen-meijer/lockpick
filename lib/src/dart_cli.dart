import 'package:indent/indent.dart';
import 'package:io/ansi.dart';
import 'package:mason/mason.dart';
import 'package:universal_io/io.dart';

/// {@template dart_cli}
/// A simple wrapper around the Dart CLI.
/// {@endtemplate}
class DartCli {
  /// {@macro dart_cli}
  DartCli({
    Logger? logger,
  }) : _logger = logger ?? Logger();

  final Logger _logger;

  /// Runs `pub get`.
  ///
  /// If [useFlutter] is set to `true`, this will run `flutter pub get`.
  Future<void> pubGet({
    bool useFlutter = false,
    String? workingDirectory,
  }) {
    return _run(
      useFlutter ? 'flutter' : 'dart',
      ['pub', 'get'],
      workingDirectory: workingDirectory,
    );
  }

  Future<ProcessResult> _run(
    String cmd,
    List<String> args, {
    String? workingDirectory,
  }) async {
    final fullCommand = [cmd, ...args].join(' ');
    final stopProgress = _logger.progress('Running `$fullCommand`...');

    final result = await Process.run(
      cmd,
      args,
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    stopProgress();

    if (result.exitCode != 0) {
      final values = {
        'Standard out': result.stdout.toString().trim(),
        'Standard error': result.stderr.toString().trim()
      }..removeWhere((k, v) => v.isEmpty);

      var message = 'Unknown error';
      if (values.isNotEmpty) {
        message = values.entries
            .map((e) => '${e.key}\n${e.value.indent(2)}')
            .join('\n\n');
      }

      _logger.err(styleBold.wrap('Error while running `$fullCommand`'));
      throw ProcessException(cmd, args, message, result.exitCode);
    }

    return result;
  }
}
