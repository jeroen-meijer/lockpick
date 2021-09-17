import 'package:lockpick/lockpick.dart';
import 'package:lockpick/src/extensions/extensions.dart';
import 'package:lockpick/src/logger/logger.dart';
import 'package:yaml/yaml.dart';

/// {@template lockpick}
/// A CLI for copying pubspec.lock dependency versions to pubspec.yaml files.
/// {@endtemplate}
class LockpickCli {
  /// {@macro lockpick}
  const LockpickCli({
    required this.launchConfig,
  });

  /// The configuration for the CLI.
  final LaunchConfig launchConfig;

  Future<void> run() async {
    final lockPackages = await _getLockPackages();

    final dependencies = await _getHostedPubspecDependencies();

    final isFlutterProject =
        dependencies.any((dependency) => dependency.name == 'flutter');

    final pubspecUsesCaretSyntax =
        dependencies.any((dependency) => dependency.version.contains('^'));
    final useCaretSyntax = launchConfig.caretSyntaxPreference.map((preference) {
      if (preference == CaretSyntaxPreference.auto) {
        return pubspecUsesCaretSyntax;
      } else {
        return preference == CaretSyntaxPreference.always;
      }
    });

    var dependenciesToReplace = dependencies;

    if (launchConfig.shouldOnlyReplaceEmpty) {
      dependenciesToReplace = dependenciesToReplace
          .where((dependency) =>
              dependency.version.isEmpty || dependency.version == 'null')
          .toList();
    }

    final dependencyChanges = dependenciesToReplace.map((dependency) {
      final lockPackageCandidates = lockPackages.where(
        (lockPackage) => lockPackage.name == dependency.name,
      );
      if (lockPackageCandidates.isEmpty) {
        throw Exception('''
Could not find the dependency "${dependency.name}" in the lockfile.

Try running `${!isFlutterProject ? '' : 'flutter '}pub get` to update the lockfile.

If this error keeps occurring, this should be considered a bug in the
Lockpick CLI. In that case, please file an issue at

  https://github.com/jeroen-meijer/lockpick/issues

and include the contents of your lockfile.

        ''');
      }

      final lockPackage = lockPackageCandidates.first;
      final newVersion = '${!useCaretSyntax ? '' : '^'}${lockPackage.version}';

      return DependencyChange(
        name: dependency.name,
        originalVersion: dependency.version,
        newVersion: newVersion,
      );
    }).toList(growable: false);

    if (dependencyChanges.isEmpty ||
        dependencyChanges.every((change) => !change.hasChange)) {
      log('No dependencies to replace.');
    } else {
      log('Replacing dependencies in pubspec.yaml file...');
      await _writeDependencies(dependencyChanges);
    }

    log('\nDone!');
  }

  Future<List<SimpleDependency>> _getLockPackages() async {
    try {
      final lockFileContents = await launchConfig.lockFile.readAsString();
      final lockMap =
          loadYamlDocument(lockFileContents).contents.value as YamlMap;

      final lockPackagesMap = lockMap['packages'] as YamlMap;
      final lockPackages = lockPackagesMap.entries.map((entry) {
        final name = entry.key as String;
        final packageData = entry.value as YamlMap;
        final version = packageData['version'] as String;

        return SimpleDependency(
          name: name,
          version: version,
        );
      }).toList(growable: false);

      return lockPackages;
    } catch (e) {
      throw Exception('''
An error occurred while parsing the lockfile ("pubspec.lock").

Pl
''');
    }
  }

  Future<List<SimpleDependency>> _getHostedPubspecDependencies() async {
    final yamlFileContents = await launchConfig.yamlFile.readAsString();
    final pubspecMap =
        loadYamlDocument(yamlFileContents).contents.value as YamlMap;

    final pubspecDependencies = pubspecMap['dependencies'] as YamlMap;
    final pubspecDependenciesList = pubspecDependencies.entries
        .where((entry) => entry.value is String || entry.value == null)
        .map((entry) => SimpleDependency(
              name: entry.key as String,
              version: '${entry.value ?? ''}',
            ))
        .toList(growable: false);

    return pubspecDependenciesList;
  }

  Future<void> _writeDependencies(List<DependencyChange> changes) async {
    final yamlFileString = await launchConfig.yamlFile.readAsString();
    final yamlFileLines = yamlFileString.split('\n');

    var hasEncounteredDependenciesHeader = false;

    for (var i = 0; i < yamlFileLines.length; i++) {
      final line = yamlFileLines[i];
      if (!hasEncounteredDependenciesHeader) {
        if (line.trim() == 'dependencies:') {
          hasEncounteredDependenciesHeader = true;
        }
      } else {
        final dependencyName = line.trim().split(':').first;
        final hasMatch =
            changes.any((dependency) => dependency.name == dependencyName);
        if (hasMatch) {
          final change = changes
              .firstWhere((dependency) => dependency.name == dependencyName);
          log(
            '- "${change.name}": '
            '${change.originalVersion} -> ${change.newVersion}'
            '${change.hasChange ? '' : ' (no change)'}',
          );
          final firstCharIndex =
              line.split('').indexWhere((char) => char != ' ');
          final whitespace = ' ' * firstCharIndex;
          final dependencyString =
              '$whitespace${change.name}: ${change.newVersion}';
          yamlFileLines[i] = dependencyString;
        }
      }
    }

    await launchConfig.yamlFile.writeAsString(yamlFileLines.join('\n'));
  }
}
