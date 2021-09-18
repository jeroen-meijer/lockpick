import 'dart:convert';

import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:equatable/equatable.dart';
import 'package:io/ansi.dart';
import 'package:lockpick/src/dart_cli.dart';
import 'package:lockpick/src/extensions/extensions.dart';
import 'package:lockpick/src/models/models.dart';
import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';
import 'package:yaml/yaml.dart';

/// {@template sync_command}
/// Syncs dependencies between a pubspec.yaml and a pubspec.lock file.
///
/// Usage: `lockpick` or `lockpick sync`
/// {@endtemplate}
class SyncCommand extends Command<int> {
  SyncCommand({
    DartCli? dartCli,
    Logger? logger,
  })  : _dartCli = dartCli ?? DartCli(),
        _logger = logger ?? Logger() {
    argParser
      ..addVerboseFlag()
      ..addFlag(
        'empty-only',
        abbr: 'e',
        help: 'Only add dependency versions in the pubspec.yaml for which '
            'there is no specific version set.',
      )
      ..addOption(
        'caret-syntax-preference',
        abbr: 'c',
        help: 'Specifies a preference for using caret syntax (^X.Y.Z).',
        allowed: [
          CaretSyntaxPreference.auto.describe(),
          CaretSyntaxPreference.always.describe(),
          CaretSyntaxPreference.never.describe(),
        ],
        allowedHelp: {
          CaretSyntaxPreference.auto.describe(): 'Interpret caret syntax '
              'preference from existing dependencies in the pubspec.yaml file '
              'if possible. Will default to "always" if no existing '
              'dependencies are found.',
          CaretSyntaxPreference.always.describe(): 'Always use caret syntax.',
          CaretSyntaxPreference.never.describe(): 'Never use caret syntax.',
        },
        defaultsTo: CaretSyntaxPreference.auto.describe(),
      )
      ..addMultiOption(
        'dependency-types',
        aliases: ['types'],
        abbr: 'd',
        help: 'Specifies what type of dependencies to sync. '
            'Will sync all dependencies by default.',
        allowed: [
          DependencyType.main.describe(),
          DependencyType.dev.describe(),
        ],
        allowedHelp: {
          DependencyType.main.describe():
              'Sync main dependencies. Enabled by default.',
          DependencyType.dev.describe():
              'Sync dev_dependencies. Enabled by default.',
        },
        valueHelp: 'main,dev',
        defaultsTo: [
          DependencyType.main.describe(),
          DependencyType.dev.describe(),
        ],
      );
  }

  final DartCli _dartCli;
  final Logger _logger;

  @override
  String get description =>
      'Syncs dependencies between a pubspec.yaml and a pubspec.lock file. '
      'Will run "pub get" or "flutter pub get" in the specified project path.';

  @override
  String get summary => '$invocation\n$description';

  @override
  String get name => 'sync';

  @override
  String get invocation => 'lockpick sync [project_path]';

  /// [ArgResults] which can be overridden for testing.
  @visibleForTesting
  ArgResults? argResultOverrides;

  ArgResults get _argResults => argResultOverrides ?? argResults!;

  @override
  Future<int> run() async {
    if (isVerboseEnabled) {
      _logger.debug('Running in verbose mode.');
    }

    final emptyOnly = _argResults['empty-only'] as bool;

    final workingDirectory = _argResults.rest.isEmpty
        ? Directory.current
        : Directory(_argResults.rest.first);

    Directory.current = workingDirectory;

    if (!workingDirectory.existsSync()) {
      throw Exception('Given path "${workingDirectory.path}" does not exist.');
    } else if (!workingDirectory.containsFileSync('pubspec.yaml')) {
      if (workingDirectory.isCurrent) {
        throw Exception(
          'Current directory does not contain a pubspec.yaml file. '
          'Please specify a path to a Dart or Flutter project containing a '
          'pubspec.yaml file.',
        );
      } else {
        throw Exception(
          'Given path "${workingDirectory.path}" does not contain a '
          'pubspec.yaml file. Please specify a path to a Dart or Flutter '
          'project containing a pubspec.yaml file.',
        );
      }
    }

    await _dartCli.pubGet(
      workingDirectory: workingDirectory.path,
    );

    final caretSyntaxPreferenceString =
        _argResults['caret-syntax-preference'] as String;
    final caretSyntaxPreference =
        CaretSyntaxPreference.values.findEnumValue(caretSyntaxPreferenceString);

    final dependencyTypesString =
        _argResults['dependency-types'] as List<String>;
    final dependencyTypes = dependencyTypesString
        .map((dependencyTypeString) =>
            DependencyType.values.findEnumValue(dependencyTypeString))
        .toList(growable: false);

    final args = SyncArgs(
      emptyOnly: emptyOnly,
      workingDirectory: workingDirectory,
      caretSyntaxPreference: caretSyntaxPreference,
      dependencyTypes: dependencyTypes,
      isVerboseEnabled: isVerboseEnabled,
    );

    return Sync(
      args: args,
      logger: _logger,
    ).run();
  }
}

/// {@template sync_args}
/// The arguments for the `lockpick sync` command.
/// {@endtemplate}
class SyncArgs extends Equatable {
  const SyncArgs({
    required this.emptyOnly,
    required this.workingDirectory,
    required this.caretSyntaxPreference,
    required this.dependencyTypes,
    required this.isVerboseEnabled,
  });

  final bool emptyOnly;
  final Directory workingDirectory;
  final CaretSyntaxPreference caretSyntaxPreference;
  final List<DependencyType> dependencyTypes;
  final bool isVerboseEnabled;

  @override
  List<Object> get props => [
        emptyOnly,
        workingDirectory,
        caretSyntaxPreference,
        dependencyTypes,
        isVerboseEnabled,
      ];
}

/// {@template sync}
/// The runner for the `lockpick sync` command.
/// {@endtemplate}
@visibleForTesting
class Sync {
  Sync({
    required SyncArgs args,
    Logger? logger,
  })  : _args = args,
        _logger = logger ?? Logger();

  final SyncArgs _args;
  final Logger _logger;

  File get _pubspecYamlFile =>
      File(path.join(_args.workingDirectory.path, 'pubspec.yaml'));

  File get _pubspecLockFile =>
      File(path.join(_args.workingDirectory.path, 'pubspec.lock'));

  Future<Map<String, dynamic>> _loadYamlFile(File file) async {
    final contents = await file.readAsString();
    final yaml = loadYaml(contents) as YamlMap;
    return Map<String, dynamic>.from(yaml);
  }

  Future<int> run() async {
    final lockMap = await _loadYamlFile(_pubspecLockFile);
    final lockPackages =
        Map<String, YamlMap>.from(lockMap['packages'] as YamlMap).entries;
    final directPackages = lockPackages
        .where((entry) {
          final dependency = entry.value['dependency'] as String;
          return dependency.startsWith('direct');
        })
        .map((entry) => SimpleDependency(
              name: entry.key,
              version: entry.value['version'] as String,
              type: entry.value['dependency'] == 'direct main'
                  ? DependencyType.main
                  : DependencyType.dev,
            ))
        .toList(growable: false);

    final pubspecMap = await _loadYamlFile(_pubspecYamlFile);
    final dependencies =
        // TODO: Add support for `dev_dependencies`
        // and remove hard-coded "dependencies" key.
        Map<String, dynamic>.from(pubspecMap['dependencies'] as YamlMap)
            .entries
            .where((entry) => entry.value == null || entry.value is String)
            .map((entry) => SimpleDependency(
                  name: entry.key,
                  version: '${entry.value ?? ''}',
                ))
            .toList(growable: false);

    _logger.info('This command has not been implemented yet.');

    if (_args.isVerboseEnabled) {
      _logger.debug(lightGray.wrap(const JsonEncoder.withIndent('  ').convert({
        'debug_data': {
          'direct_packages': directPackages.map((p) => p.name).toList(),
          'dependencies': dependencies.map((p) => p.name).toList(),
        },
      })));
    }

    return 0;
  }
}
