import 'package:equatable/equatable.dart';
import 'package:lockpick/src/models/models.dart';

class SimpleDependency extends Equatable {
  const SimpleDependency({
    required this.name,
    required this.version,
    this.type = DependencyType.main,
  });

  final String name;
  final String version;
  final DependencyType type;

  @override
  List<Object> get props => [name, version, type];

  SimpleDependency copyWith({
    String? name,
    String? version,
    DependencyType? type,
  }) {
    return SimpleDependency(
      name: name ?? this.name,
      version: version ?? this.version,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'version': version,
      'type': type.describe(),
    };
  }
}
