import 'package:coverage_viewer/src/parser/lcov_parser.dart';
import 'package:test/test.dart';

void main() {
  group('LcovParser', () {
    late LcovParser parser;

    setUp(() {
      parser = LcovParser();
    });

    test('should parse simple lcov file with one file', () {
      const lcovContent = '''
SF:lib/example.dart
DA:1,2
DA:2,0
DA:3,5
LF:3
LH:2
end_of_record
''';

      final report = parser.parse(lcovContent);

      expect(report.files.length, 1, reason: 'Should have exactly 1 file');
      expect(report.files.first.path, 'lib/example.dart');
      expect(report.files.first.totalLines, 3);
      expect(report.files.first.coveredLines, 2);
      expect(report.files.first.lineHits[1], 2);
      expect(report.files.first.lineHits[2], 0);
      expect(report.files.first.lineHits[3], 5);
    });

    test('should parse multiple files', () {
      const lcovContent = '''
SF:lib/file1.dart
DA:1,1
LF:1
LH:1
end_of_record
SF:lib/file2.dart
DA:1,0
DA:2,3
LF:2
LH:1
end_of_record
''';

      final report = parser.parse(lcovContent);

      expect(report.files.length, 2);
      expect(report.files[0].path, 'lib/file1.dart');
      expect(report.files[1].path, 'lib/file2.dart');
    });

    test('should calculate coverage percentage correctly', () {
      const lcovContent = '''
SF:lib/example.dart
DA:1,1
DA:2,1
DA:3,0
DA:4,0
LF:4
LH:2
end_of_record
''';

      final report = parser.parse(lcovContent);
      final file = report.files.first;

      expect(file.coveragePercent, 50.0);
    });

    test('should handle empty lcov content', () {
      const lcovContent = '';

      final report = parser.parse(lcovContent);

      expect(report.files.length, 0);
      expect(report.totalLines, 0);
      expect(report.coveredLines, 0);
      expect(report.coveragePercent, 0);
    });

    test('should handle file with no coverage data', () {
      const lcovContent = '''
SF:lib/example.dart
LF:0
LH:0
end_of_record
''';

      final report = parser.parse(lcovContent);

      expect(report.files.length, 1);
      expect(report.files.first.totalLines, 0);
      expect(report.files.first.coveragePercent, 0);
    });

    test('should handle Windows paths with backslashes', () {
      const lcovContent = '''
SF:lib\\features\\auth\\user.dart
DA:1,1
LF:1
LH:1
end_of_record
''';

      final report = parser.parse(lcovContent);

      expect(report.files.length, 1);
      expect(report.files.first.path, 'lib\\features\\auth\\user.dart');
    });

    test('should ignore invalid DA lines', () {
      const lcovContent = '''
SF:lib/example.dart
DA:1,1
DA:invalid
DA:2,2
LF:2
LH:2
end_of_record
''';

      final report = parser.parse(lcovContent);

      expect(report.files.first.lineHits.length, 2);
      expect(report.files.first.lineHits[1], 1);
      expect(report.files.first.lineHits[2], 2);
    });

    test('should calculate total coverage for multiple files', () {
      const lcovContent = '''
SF:lib/file1.dart
DA:1,1
DA:2,1
LF:2
LH:2
end_of_record
SF:lib/file2.dart
DA:1,0
DA:2,0
LF:2
LH:0
end_of_record
''';

      final report = parser.parse(lcovContent);

      expect(report.totalLines, 4);
      expect(report.coveredLines, 2);
      expect(report.coveragePercent, 50.0);
    });

    test('should handle lines with multiple commas in DA', () {
      const lcovContent = '''
SF:lib/example.dart
DA:1,5,extra
DA:2,0,data
LF:2
LH:1
end_of_record
''';

      final report = parser.parse(lcovContent);

      expect(report.files.first.lineHits[1], 5);
      expect(report.files.first.lineHits[2], 0);
    });
  });
}
