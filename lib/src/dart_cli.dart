import 'package:indent/indent.dart';
import 'package:io/ansi.dart';
import 'package:lockpick/src/logger.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:yaml/yaml.dart';

/// {@template dart_cli}
/// A simple wrapper around the Dart CLI.
/// {@endtemplate}
class DartCli {
  /// {@macro dart_cli}
  DartCli({Logger? logger}) : _logger = logger ?? Logger();

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
    final pubspecContents = await File(
      path.join(projectPath, 'pubspec.yaml'),
    ).readAsString();
    final pubspecYamlMap = loadYaml(pubspecContents);

    if (pubspecYamlMap case {'dependencies': {'flutter': _?}}) {
      return true;
    } else {
      return false;
    }
  }

  /// Returns true if the project at the given [path] is an FVM project.
  ///
  /// The provided [path] be a directory and contain a `.fvm` directory with
  /// an `fvm_config.json` file.
  bool isFvmProject(String projectPath) {
    final fvmRcPath = path.join(projectPath, '.fvmrc');
    final fvmConfigPath = path.join(projectPath, '.fvm', 'fvm_config.json');

    return [fvmRcPath, fvmConfigPath].any((p) => File(p).existsSync());
  }

  /// Runs `dart pub upgrade` or `flutter pub upgrade`.
  Future<void> pubUpgrade({String? workingDirectory}) async {
    await runDartOrFlutterCommand([
      'pub',
      'upgrade',
    ], workingDirectory: workingDirectory);
  }

  /// Runs `dart pub get` or `flutter pub get`.
  Future<void> pubGet({String? workingDirectory}) async {
    return runDartOrFlutterCommand([
      'pub',
      'get',
    ], workingDirectory: workingDirectory);
  }

  /// Runs the given Flutter or Dart command.
  ///
  /// - If this project uses FVM, the command will be run with `fvm`.
  /// - If this project is a Flutter project, the command will be run with
  ///   `flutter`. Otherwise, it will be run with `dart`.
  Future<void> runDartOrFlutterCommand(
    List<String> commandParts, {
    String? workingDirectory,
  }) async {
    final useFlutter = await isFlutterProject(workingDirectory ?? '.');
    final useFvm = isFvmProject(workingDirectory ?? '.');
    final fullCommandParts = [
      if (useFvm) 'fvm',
      if (useFlutter) 'flutter' else 'dart',
      ...commandParts,
    ];

    await _run(
      fullCommandParts.first,
      fullCommandParts.skip(1).toList(),
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
        'Standard error': result.stderr.toString().trim(),
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
