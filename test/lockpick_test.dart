// ignore_for_file: prefer_const_constructors
import 'package:lockpick/src/command_runner.dart';
import 'package:test/test.dart';

void main() {
  group('Lockpick', () {
    test('example test', () {
      expect(
        LockpickCommandRunner(),
        isA<LockpickCommandRunner>(),
      );
    });
  });
}
