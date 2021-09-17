import 'package:equatable/equatable.dart';

class DependencyChange extends Equatable {
  const DependencyChange({
    required this.name,
    required this.originalVersion,
    required this.newVersion,
  });

  final String name;
  final String originalVersion;
  final String newVersion;

  bool get hasChange => originalVersion != newVersion;

  @override
  List<Object> get props => [name, originalVersion, newVersion];
}
