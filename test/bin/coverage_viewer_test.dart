import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('CLI executable', () {
    final executablePath = 'bin/coverage_viewer.dart';

    test('should show help when --help flag is provided', () async {
      final result = await Process.run(
        'dart',
        ['run', executablePath, '--help'],
      );

      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('Coverage viewer'));
      expect(result.stdout.toString(), contains('Usage:'));
      expect(result.stdout.toString(), contains('--input'));
      expect(result.stdout.toString(), contains('--port'));
    });

    test('should show help when -h flag is provided', () async {
      final result = await Process.run(
        'dart',
        ['run', executablePath, '-h'],
      );

      expect(result.exitCode, 0);
      expect(result.stdout.toString(), contains('Coverage viewer'));
    });

    test('should show error when lcov file does not exist', () async {
      final result = await Process.run(
        'dart',
        ['run', executablePath, '--input', 'non_existent_file.info'],
      );

      expect(result.exitCode, 1);
      expect(result.stdout.toString(), contains('Error: File not found'));
      expect(result.stdout.toString(), contains('non_existent_file.info'));
    });

    test('should accept custom input path', () async {
      final tempDir = await Directory.systemTemp.createTemp('coverage_test_');
      final tempFile = File('${tempDir.path}/test.lcov');
      await tempFile.writeAsString('''
        SF:lib/test.dart
        DA:1,1
        LF:1
        LH:1
        end_of_record
        ''');

      final process = await Process.start(
        'dart',
        ['run', executablePath, '--input', tempFile.path, '--port', '0'],
      );

      await Future.delayed(Duration(milliseconds: 500));

      expect(process.pid, greaterThan(0));

      process.kill();
      await tempDir.delete(recursive: true);
    });

    test('should accept custom port', () async {
      final tempDir = await Directory.systemTemp.createTemp('coverage_test_');
      final tempFile = File('${tempDir.path}/test.lcov');
      await tempFile.writeAsString('''
        SF:lib/test.dart
        DA:1,1
        LF:1
        LH:1
        end_of_record
        ''');

      final process = await Process.start(
        'dart',
        ['run', executablePath, '-i', tempFile.path, '-p', '9999'],
      );

      final outputLines = <String>[];
      process.stdout
          .transform(SystemEncoding().decoder)
          .listen((line) => outputLines.add(line));

      await Future.delayed(Duration(seconds: 3));
      final output = outputLines.join('\n');
      expect(output, contains('9999'));

      process.kill();
      await tempDir.delete(recursive: true);
    });

    test('should handle invalid port number', () async {
      final result = await Process.run(
        'dart',
        ['run', executablePath, '--port', 'invalid'],
      );

      expect(result.exitCode, 1);
      expect(result.stdout.toString(), contains('Error'));
    });

    test('should parse arguments correctly with short flags', () async {
      final tempDir = await Directory.systemTemp.createTemp('coverage_test_');
      final tempFile = File('${tempDir.path}/test.lcov');
      await tempFile.writeAsString('''
        SF:lib/test.dart
        DA:1,1
        LF:1
        LH:1
        end_of_record
        ''');

      final process = await Process.start(
        'dart',
        ['run', executablePath, '-i', tempFile.path, '-p', '0'],
      );

      await Future.delayed(Duration(milliseconds: 500));
      expect(process.pid, greaterThan(0));

      process.kill();
      await tempDir.delete(recursive: true);
    });

    test('should use default values when no arguments provided', () async {
      final coverageDir = Directory('coverage');
      final defaultFile = File('coverage/lcov.info');

      var createdDir = false;
      var createdFile = false;

      if (!await coverageDir.exists()) {
        await coverageDir.create();
        createdDir = true;
      }

      if (!await defaultFile.exists()) {
        await defaultFile.writeAsString('''
        SF:lib/test.dart
        DA:1,1
        LF:1
        LH:1
        end_of_record
        ''');
        createdFile = true;
      }

      final process = await Process.start(
        'dart',
        ['run', executablePath, '--port', '0'],
      );

      final outputLines = <String>[];
      process.stdout
          .transform(SystemEncoding().decoder)
          .listen((line) => outputLines.add(line));

      await Future.delayed(Duration(seconds: 3));

      final output = outputLines.join('\n');
      expect(output, contains('Reading coverage from: coverage/lcov.info'));

      process.kill();

      if (createdFile) await defaultFile.delete();
      if (createdDir) await coverageDir.delete();
    });

    test('should display total files count', () async {
      final tempDir = await Directory.systemTemp.createTemp('coverage_test_');
      final tempFile = File('${tempDir.path}/test.lcov');
      await tempFile.writeAsString('''
        SF:lib/file1.dart
        DA:1,1
        LF:1
        LH:1
        end_of_record
        SF:lib/file2.dart
        DA:1,1
        LF:1
        LH:1
        end_of_record
        SF:lib/file3.dart
        DA:1,1
        LF:1
        LH:1
        end_of_record
        ''');

      final process = await Process.start(
        'dart',
        ['run', executablePath, '-i', tempFile.path, '-p', '0'],
      );

      final outputLines = <String>[];
      process.stdout
          .transform(SystemEncoding().decoder)
          .listen((line) => outputLines.add(line));

      await Future.delayed(Duration(seconds: 3));

      final output = outputLines.join('\n');
      expect(output, contains('Total files: 3'));

      process.kill();
      await tempDir.delete(recursive: true);
    });
  });
}
