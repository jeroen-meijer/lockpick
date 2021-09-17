import 'package:path/path.dart' as path;
import 'package:universal_io/io.dart';

extension DirectoryExtensions on Directory {
  /// Indicates whether this directory is the current working directory.
  bool get isCurrent => absolute.path == Directory.current.absolute.path;

  /// Returns whether a file with the given [name] name exists in this
  /// directory.
  bool containsFileSync(String name) {
    final entities = listSync();

    for (final entity in entities) {
      if (entity is File) {
        final fileName = path.basename(entity.path);
        if (fileName == name) {
          return true;
        }
      }
    }

    return false;
  }

  /// Returns whether this directory contains all files with the given
  /// [names].
  bool containsFilesSync(List<String> names) {
    for (final file in names) {
      if (!containsFileSync(file)) {
        return false;
      }
    }

    return true;
  }
}
