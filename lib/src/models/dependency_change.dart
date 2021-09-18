import 'package:equatable/equatable.dart';
import 'package:lockpick/src/models/models.dart';

class DependencyChange extends Equatable {
  const DependencyChange({
    required this.name,
    required this.originalVersion,
    required this.newVersion,
    required this.type,
  });

  final String name;
  final String originalVersion;
  final String newVersion;
  final DependencyType type;

  bool get hasChange => originalVersion.replaceAll('^', '') != newVersion;

  @override
  List<Object> get props => [name, originalVersion, newVersion, type];
}
