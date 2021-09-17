import 'dart:io';

import 'package:lockpick/lockpick.dart';
import 'package:lockpick/src/logger/logger.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> args) async {
  log('--- Lockpick CLI ---');

  final workingDirectory = resolveDirectory(args.isEmpty ? null : args.first);

  // Check and change working directory.
  if (!workingDirectory.isCurrent) {
    if (!workingDirectory.existsSync()) {
      throw Exception(
        'Working directory "${workingDirectory.path}" does not exist.',
      );
    }

    log('Changing working directory to "${workingDirectory.path}".');
    Directory.current = workingDirectory;
  }

  // Throw error if working directory does not contain a "pubspec.yaml" file.
  if (!workingDirectory.containsFile('pubspec.yaml')) {
    throw Exception(
      'Current directory ("${workingDirectory.path}") does not contain '
      'a "pubspec.yaml" file.',
    );
  }

  // Throw error if working directory does not contain a "pubspec.lock" file.
  if (!workingDirectory.containsFile('pubspec.lock')) {
    throw Exception(
      'Current directory ("${workingDirectory.path}") does not contain '
      'a "pubspec.lock" file.',
    );
  }

  await LockpickCli(
    launchConfig: LaunchConfig(
      yamlFile: File(path.join(workingDirectory.path, 'pubspec.yaml')),
      lockFile: File(path.join(workingDirectory.path, 'pubspec.lock')),
    ),
  ).run();
}

Directory resolveDirectory(String? pathArg) {
  if (pathArg == null) {
    return Directory.current;
  } else {
    if (path.isAbsolute(pathArg)) {
      return Directory(pathArg);
    } else {
      return Directory(
        path.absolute(
          path.join(
            path.current,
            pathArg,
          ),
        ),
      );
    }
  }
}

extension on Directory {
  bool get isCurrent => absolute.path == Directory.current.absolute.path;
  bool containsFile(String name) =>
      listSync().any((entity) => path.split(entity.path).last == name);
}
