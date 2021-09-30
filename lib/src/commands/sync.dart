import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:equatable/equatable.dart';
import 'package:io/ansi.dart';
import 'package:lockpick/src/dart_cli.dart';
import 'package:lockpick/src/extensions/extensions.dart';
import 'package:lockpick/src/logger.dart';
import 'package:lockpick/src/models/models.dart';
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
              'if possible. Will default to "always" if no trend is detected.',
          CaretSyntaxPreference.always.describe(): 'Always use caret syntax.',
          CaretSyntaxPreference.never.describe(): 'Never use caret syntax.',
        },
        defaultsTo: CaretSyntaxPreference.auto.describe(),
      )
      ..addMultiOption(
        'dependency-types',
        aliases: ['types'],
        abbr: 't',
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
      )
      ..addFlag(
        'dry-run',
        abbr: 'd',
        help:
            'Only print the changes that would be made, but do not make them. '
            'When set, the exit code will indicate if a change would have been '
            'made. Useful for running in CI workflows.',
      );
  }

  final DartCli _dartCli;
  final Logger _logger;

  @override
  String get description =>
      'Syncs dependencies between a pubspec.yaml and a pubspec.lock file. '
      'Will run "[flutter] pub get" and "[flutter] pub upgade" in '
      'the specified project path before syncing.';

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
    Logger.verboseEnabled = isVerboseFlagSet;

    _logger.debug('Running in verbose mode.');

    final emptyOnly = _argResults['empty-only'] as bool;
    final dryRun = _argResults['dry-run'] == true;

    if (dryRun) {
      _logger.alert('Running in dry-run mode. No actual changes will be made.');
    }

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

    await _dartCli.pubGet(workingDirectory: workingDirectory.path);

    // Only run pub upgrade when not running in dry-run mode.
    if (dryRun) {
      _logger.info('Avoiding running pub upgrade in dry-run mode.');
    } else {
      await _dartCli.pubUpgrade(workingDirectory: workingDirectory.path);
    }

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
      dryRun: dryRun,
      workingDirectory: workingDirectory,
      caretSyntaxPreference: caretSyntaxPreference,
      dependencyTypes: dependencyTypes,
    );

    final result = await Sync(
      args: args,
      logger: _logger,
    ).run();

    if (dryRun) {
      return result.didMakeChanges ? 1 : 0;
    }

    if (result.didMakeChanges) {
      await _dartCli.pubGet(workingDirectory: workingDirectory.path);
    }

    return 0;
  }
}

/// {@template sync_args}
/// The arguments for the `lockpick sync` command.
/// {@endtemplate}
class SyncArgs extends Equatable {
  const SyncArgs({
    required this.emptyOnly,
    required this.dryRun,
    required this.workingDirectory,
    required this.caretSyntaxPreference,
    required this.dependencyTypes,
  });

  final bool emptyOnly;
  final bool dryRun;
  final Directory workingDirectory;
  final CaretSyntaxPreference caretSyntaxPreference;
  final List<DependencyType> dependencyTypes;

  @override
  List<Object> get props => [
        emptyOnly,
        dryRun,
        workingDirectory,
        caretSyntaxPreference,
        dependencyTypes,
      ];
}

/// {@template sync_result}
/// The result of running the `lockpick sync` command.
/// {@endtemplate}
class SyncResult extends Equatable {
  /// {@macro sync_result}
  const SyncResult({
    required this.didMakeChanges,
  });

  final bool didMakeChanges;

  @override
  List<Object?> get props => [didMakeChanges];
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
    _logger.debug('Loading ${file.absolute.path}...');
    final contents = await file.readAsString();
    final yaml = loadYaml(contents) as YamlMap;
    _logger.debug('Loaded and parsed ${file.absolute.path}.');
    return Map<String, dynamic>.from(yaml);
  }

  Future<List<SimpleDependency>> _getDirectLockPackages() async {
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

    return directPackages;
  }

  Future<List<SimpleDependency>> _getAllPubspecDependencies() async {
    final pubspecMap = await _loadYamlFile(_pubspecYamlFile);

    final dependencies = <SimpleDependency>[];

    for (final type in DependencyType.values) {
      final depsForTypeYamlMap = pubspecMap[type.getPubspecName()] as YamlMap;
      final depsForType = Map<String, dynamic>.from(depsForTypeYamlMap)
          .entries
          .where((entry) => entry.value == null || entry.value is String)
          .map((entry) => SimpleDependency(
                name: entry.key,
                version: '${entry.value ?? ''}',
                type: type,
              ));
      dependencies.addAll(depsForType);
    }

    return dependencies;
  }

  Future<bool> _getCaretUsageTrend(List<SimpleDependency> dependencies) async {
    final allDepsAmount = dependencies.length;
    final caretsUsed = dependencies
        .map((dep) => dep.version)
        .where((version) => version.startsWith('^'))
        .length;

    _logger.debug('$caretsUsed out of $allDepsAmount dependencies use carets.');

    final caretUsageFactor = caretsUsed / allDepsAmount;
    return caretUsageFactor >= 0.5;
  }

  Future<String> _applyChangeToContent({
    required String contents,
    required DependencyChange change,
    required bool useCaretSyntax,
  }) async {
    final lines = contents.split('\n');
    final dependencyTypeName = change.type.getPubspecName();

    var hasEncounteredType = false;
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();
      final colonIndex = trimmed.indexOf(':');
      if (colonIndex != -1) {
        final key = trimmed.substring(0, colonIndex);
        if (key == dependencyTypeName) {
          hasEncounteredType = true;
        } else if (hasEncounteredType && key == change.name) {
          final firstCharIndex =
              line.split('').indexWhere((char) => char != ' ');
          final whitespace = ' ' * firstCharIndex;
          final newVersionString =
              '${useCaretSyntax ? '^' : ''}${change.newVersion}';
          lines[i] = '$whitespace${change.name}: $newVersionString';
        }
      }
    }

    assert(hasEncounteredType);

    return lines.join('\n');
  }

  Future<SyncResult> run() async {
    _logger.debug('Running sync command with args: $_args');

    void Function() stopProgress;

    stopProgress = _logger.progress('Fetching pubspec.lock...');
    final directLockPackages = await _getDirectLockPackages();
    stopProgress();

    stopProgress = _logger.progress('Fetching pubspec.yaml...');
    final allPubspecDependencies = await _getAllPubspecDependencies();
    stopProgress();

    final useCaretSyntax =
        _args.caretSyntaxPreference == CaretSyntaxPreference.auto
            ? await _getCaretUsageTrend(allPubspecDependencies)
            : _args.caretSyntaxPreference == CaretSyntaxPreference.always;

    if (useCaretSyntax) {
      _logger.info('Using caret syntax.');
    } else {
      _logger.info('Not using caret syntax.');
    }

    stopProgress = _logger.progress('Queueing changes...');
    final allChanges = <DependencyChange>[];
    for (final type in _args.dependencyTypes) {
      final dependenciesForType =
          allPubspecDependencies.where((dep) => dep.type == type);
      for (final dependency in dependenciesForType) {
        final package =
            directLockPackages.firstWhere((dep) => dep.name == dependency.name);
        allChanges.add(DependencyChange(
          name: dependency.name,
          originalVersion: dependency.version,
          newVersion: package.version,
          type: type,
        ));
      }
    }
    stopProgress();

    _logger
      ..info('')
      ..info(styleBold.wrap('Queued changes'));
    for (final type in _args.dependencyTypes) {
      _logger.info('${type.getPubspecName()}:');

      final changesForType = allChanges.where((change) => change.type == type);
      for (final change in changesForType) {
        final originalVersionString =
            change.originalVersion.orIfEmpty(styleItalic.wrap('empty')!);

        if (!change.hasChange) {
          _logger.info(lightGray.wrap(
            '  ${change.name} ($originalVersionString)',
          ));
        } else {
          final icon = change.originalVersion.isEmpty
              ? green.wrap('+')
              : lightGreen.wrap('↑');
          final newVersionString = styleBold
              .wrap('${useCaretSyntax ? '^' : ''}${change.newVersion}');

          _logger.info(
            '$icon ${change.name} '
            '($originalVersionString -> '
            '$newVersionString)',
          );
        }
      }
    }

    _logger.info('');

    final applyableChanges = allChanges.where((change) => change.hasChange);

    if (_args.dryRun) {
      if (applyableChanges.isNotEmpty) {
        _logger.warn('Dry-run mode: some changes would be made.');
        return const SyncResult(didMakeChanges: true);
      } else {
        _logger.alert('Dry-run mode: no changes would be made.');
        return const SyncResult(didMakeChanges: false);
      }
    }

    if (applyableChanges.isEmpty) {
      _logger.alert('No changes to apply.');
      return const SyncResult(didMakeChanges: false);
    }

    stopProgress = _logger.progress('Preparing changes...');
    var pubspecContents = await _pubspecYamlFile.readAsString();
    for (final type in _args.dependencyTypes) {
      final changesForType =
          applyableChanges.where((change) => change.type == type);
      for (final change in changesForType) {
        pubspecContents = await _applyChangeToContent(
          contents: pubspecContents,
          change: change,
          useCaretSyntax: useCaretSyntax,
        );
      }
    }
    stopProgress();

    stopProgress = _logger.progress('Applying changes...');
    await _pubspecYamlFile.writeAsString(pubspecContents);
    stopProgress();

    return const SyncResult(didMakeChanges: true);
  }
}
