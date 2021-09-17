import 'package:equatable/equatable.dart';

class SimpleDependency extends Equatable {
  const SimpleDependency({
    required this.name,
    required this.version,
  });

  final String name;
  final String version;

  @override
  List<Object> get props => [name, version];

  SimpleDependency copyWith({
    String? name,
    String? version,
  }) {
    return SimpleDependency(
      name: name ?? this.name,
      version: version ?? this.version,
    );
  }
}
