import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:lockpick/src/models/models.dart';

/// {@template launch_config}
/// The launch configuration for the Lockpick CLI.
///
/// Both the [yamlFile] and [lockFile] must be set and valid.
///
/// If [shouldOnlyReplaceEmpty] is set to `true` (the default), only
/// dependencies that don't have explicit versions set in the [yamlFile] will
/// be replaced with the version set in the [lockFile].
/// {@endtemplate}
class LaunchConfig extends Equatable {
  /// {@macro launch_config}
  const LaunchConfig({
    required this.yamlFile,
    required this.lockFile,
    this.shouldOnlyReplaceEmpty = true,
    this.caretSyntaxPreference = CaretSyntaxPreference.auto,
  });

  /// The YAML file to update.
  ///
  /// This file is guaranteed to exist.
  final File yamlFile;

  /// The lock file to use as origin to copy over dependency versions.
  ///
  /// This file is guaranteed to exist.
  final File lockFile;

  /// Whether to only replace dependencies that don't have explicit versions set
  /// in the [yamlFile].
  ///
  /// Defaults to `true`.
  final bool shouldOnlyReplaceEmpty;

  /// TODO: Document this.
  final CaretSyntaxPreference caretSyntaxPreference;

  @override
  List<Object> get props => [yamlFile, lockFile, shouldOnlyReplaceEmpty];
}
