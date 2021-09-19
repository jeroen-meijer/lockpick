import 'package:indent/indent.dart';
import 'package:io/ansi.dart';
import 'package:lockpick/src/logger.dart';
import 'package:path/path.dart' as path;
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

  /// Returns true if the project at the given [path] is a Flutter project.
  ///
  /// The provided [path] be a directory and contain a `pubspec.yaml` file.
  /// This file will be checked for the following string:
  /// ```yaml
  /// # ...
  ///   flutter:
  ///     sdk: <version>
  /// # ...
  /// ```
  Future<bool> isFlutterProject(String projectPath) async {
    final contents =
        await File(path.join(projectPath, 'pubspec.yaml')).readAsString();
    return RegExp(r'flutter:\n[ \t]+sdk:').hasMatch(contents);
  }

  /// Runs `pub get`.
  ///
  /// If [useFlutterCli] is set to `null` (the default), the type of project
  /// will be automatically detected.
  Future<void> pubGet({
    bool? useFlutterCli,
    String? workingDirectory,
  }) async {
    final useFlutter =
        useFlutterCli ?? await isFlutterProject(workingDirectory ?? '.');

    await _run(
      useFlutter ? 'flutter' : 'dart',
      ['pub', 'get'],
      workingDirectory: workingDirectory,
    );
  }

  /// Runs `pub upgrade`.
  ///
  /// If [useFlutterCli] is set to `null` (the default), the type of project
  /// will be automatically detected.
  Future<void> pubUpgrade({
    bool? useFlutterCli,
    String? workingDirectory,
  }) async {
    final useFlutter =
        useFlutterCli ?? await isFlutterProject(workingDirectory ?? '.');

    await _run(
      useFlutter ? 'flutter' : 'dart',
      ['pub', 'upgrade'],
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
