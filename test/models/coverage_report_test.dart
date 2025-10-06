import 'package:coverage_viewer/src/models/coverage_report.dart';
import 'package:test/test.dart';

void main() {
  group('FileReport', () {
    test('should calculate coverage percentage correctly', () {
      final file = FileReport(
        path: 'lib/example.dart',
        lineHits: {1: 1, 2: 0, 3: 5},
        totalLines: 3,
        coveredLines: 2,
      );

      expect(file.coveragePercent, closeTo(66.67, 0.01));
    });

    test('should return 0 coverage for file with no lines', () {
      final file = FileReport(
        path: 'lib/empty.dart',
        lineHits: {},
        totalLines: 0,
        coveredLines: 0,
      );

      expect(file.coveragePercent, 0);
    });

    test('should extract filename from path', () {
      final file = FileReport(
        path: 'lib/features/auth/user.dart',
        lineHits: {},
        totalLines: 0,
        coveredLines: 0,
      );

      expect(file.fileName, 'user.dart');
    });

    test('should handle Windows paths in filename', () {
      final file = FileReport(
        path: 'lib\\features\\auth\\user.dart',
        lineHits: {},
        totalLines: 0,
        coveredLines: 0,
      );

      expect(file.fileName, 'user.dart');
    });
  });

  group('CoverageReport', () {
    test('should calculate total coverage from multiple files', () {
      final files = [
        FileReport(
          path: 'lib/file1.dart',
          lineHits: {1: 1, 2: 1},
          totalLines: 2,
          coveredLines: 2,
        ),
        FileReport(
          path: 'lib/file2.dart',
          lineHits: {1: 0, 2: 0},
          totalLines: 2,
          coveredLines: 0,
        ),
      ];

      final report = CoverageReport(files);

      expect(report.totalLines, 4);
      expect(report.coveredLines, 2);
      expect(report.coveragePercent, 50.0);
    });

    test('should return 0 coverage for empty report', () {
      final report = CoverageReport([]);

      expect(report.totalLines, 0);
      expect(report.coveredLines, 0);
      expect(report.coveragePercent, 0);
    });

    test('should group files by folder', () {
      final files = [
        FileReport(
          path: 'lib/features/auth/user.dart',
          lineHits: {},
          totalLines: 1,
          coveredLines: 1,
        ),
        FileReport(
          path: 'lib/features/auth/login.dart',
          lineHits: {},
          totalLines: 1,
          coveredLines: 1,
        ),
        FileReport(
          path: 'lib/core/utils.dart',
          lineHits: {},
          totalLines: 1,
          coveredLines: 1,
        ),
      ];

      final report = CoverageReport(files);
      final grouped = report.filesByFolder;

      expect(grouped.keys.length, 2);
      expect(grouped['lib/features/auth']?.length, 2);
      expect(grouped['lib/core']?.length, 1);
    });

    test('should handle files in root directory', () {
      final files = [
        FileReport(
          path: 'main.dart',
          lineHits: {},
          totalLines: 1,
          coveredLines: 1,
        ),
      ];

      final report = CoverageReport(files);
      final grouped = report.filesByFolder;

      expect(grouped['.']?.length, 1);
    });
  });

  group('FolderNode', () {
    test('should create folder tree from files with Unix paths', () {
      final files = [
        FileReport(
          path: 'lib/features/auth/user.dart',
          lineHits: {1: 1},
          totalLines: 1,
          coveredLines: 1,
        ),
        FileReport(
          path: 'lib/features/auth/login.dart',
          lineHits: {1: 0},
          totalLines: 1,
          coveredLines: 0,
        ),
        FileReport(
          path: 'lib/core/utils.dart',
          lineHits: {1: 1},
          totalLines: 1,
          coveredLines: 1,
        ),
      ];

      final report = CoverageReport(files);
      final tree = report.folderTree;

      expect(tree.children.keys, contains('lib'));
      expect(tree.children['lib']?.children.keys, contains('features'));
      expect(tree.children['lib']?.children['features']?.children.keys,
          contains('auth'));
    });

    test('should create folder tree from files with Windows paths', () {
      final files = [
        FileReport(
          path: 'lib\\features\\auth\\user.dart',
          lineHits: {1: 1},
          totalLines: 1,
          coveredLines: 1,
        ),
      ];

      final report = CoverageReport(files);
      final tree = report.folderTree;

      expect(tree.children.keys, contains('lib'));
      expect(tree.children['lib']?.children.keys, contains('features'));
    });

    test('should calculate folder coverage from children', () {
      final files = [
        FileReport(
          path: 'lib/feature/file1.dart',
          lineHits: {1: 1, 2: 1},
          totalLines: 2,
          coveredLines: 2,
        ),
        FileReport(
          path: 'lib/feature/file2.dart',
          lineHits: {1: 0, 2: 0},
          totalLines: 2,
          coveredLines: 0,
        ),
      ];

      final report = CoverageReport(files);
      final tree = report.folderTree;
      final libFolder = tree.children['lib'];
      final featureFolder = libFolder?.children['feature'];

      expect(featureFolder?.totalLines, 4);
      expect(featureFolder?.coveredLines, 2);
      expect(featureFolder?.coveragePercent, 50.0);
    });

    test('should handle files without folders', () {
      final files = [
        FileReport(
          path: 'main.dart',
          lineHits: {1: 1},
          totalLines: 1,
          coveredLines: 1,
        ),
      ];

      final report = CoverageReport(files);
      final tree = report.folderTree;

      expect(tree.files.length, 1);
      expect(tree.files.first.path, 'main.dart');
    });

    test('should identify folders with children and files', () {
      final files = [
        FileReport(
          path: 'lib/features/auth/user.dart',
          lineHits: {},
          totalLines: 1,
          coveredLines: 1,
        ),
      ];

      final report = CoverageReport(files);
      final tree = report.folderTree;
      final libFolder = tree.children['lib'];

      expect(libFolder?.hasChildren, true);
      expect(libFolder?.hasFiles, false);
      expect(libFolder?.children['features']?.children['auth']?.hasFiles, true);
    });
  });
}
