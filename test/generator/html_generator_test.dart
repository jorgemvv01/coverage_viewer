import 'package:coverage_viewer/src/generator/html_generator.dart';
import 'package:coverage_viewer/src/models/coverage_report.dart';
import 'package:test/test.dart';

void main() {
  group('HtmlGenerator', () {
    late HtmlGenerator generator;

    setUp(() {
      generator = HtmlGenerator();
    });

    group('generateIndex', () {
      test('should generate valid HTML with report data', () {
        final files = [
          FileReport(
            path: 'lib/example.dart',
            lineHits: {1: 1, 2: 0},
            totalLines: 2,
            coveredLines: 1,
          ),
        ];

        final report = CoverageReport(files);
        final html = generator.generateIndex(report);

        expect(html, contains('<!DOCTYPE html>'));
        expect(html, contains('Coverage report'));
        expect(html, contains('50.0%'));
        expect(html, contains('1 / 2'));
        expect(html, contains('1'));
      });

      test('should include search functionality', () {
        final report = CoverageReport([]);
        final html = generator.generateIndex(report);

        expect(html, contains('searchInput'));
        expect(html, contains('filterFiles'));
        expect(html, contains('Search files'));
      });

      test('should include collapse all button', () {
        final report = CoverageReport([]);
        final html = generator.generateIndex(report);

        expect(html, contains('collapseAll'));
        expect(html, contains('Collapse all'));
      });

      test('should include generation date', () {
        final report = CoverageReport([]);
        final html = generator.generateIndex(report);

        expect(html, contains('Generated on'));
      });

      test('should generate folder tree structure', () {
        final files = [
          FileReport(
            path: 'lib/features/auth/user.dart',
            lineHits: {1: 1},
            totalLines: 1,
            coveredLines: 1,
          ),
        ];

        final report = CoverageReport(files);
        final html = generator.generateIndex(report);

        expect(html, contains('folder-item'));
        expect(html, contains('folder-header'));
        expect(html, contains('lib'));
        expect(html, contains('features'));
        expect(html, contains('auth'));
      });

      test('should encode file paths in URLs', () {
        final files = [
          FileReport(
            path: 'lib/features/auth/user.dart',
            lineHits: {},
            totalLines: 1,
            coveredLines: 1,
          ),
        ];

        final report = CoverageReport(files);
        final html = generator.generateIndex(report);

        expect(
            html, contains('href="/file/lib%2Ffeatures%2Fauth%2Fuser.dart"'));
      });

      test('should show correct coverage color for high coverage', () {
        final files = [
          FileReport(
            path: 'lib/example.dart',
            lineHits: {1: 1, 2: 1, 3: 1, 4: 1, 5: 1},
            totalLines: 5,
            coveredLines: 5,
          ),
        ];

        final report = CoverageReport(files);
        final html = generator.generateIndex(report);

        expect(html, contains('#2ecc71')); // Green for >= 80%
      });

      test('should show correct coverage color for medium coverage', () {
        final files = [
          FileReport(
            path: 'lib/example.dart',
            lineHits: {1: 1, 2: 1, 3: 0, 4: 0, 5: 0},
            totalLines: 5,
            coveredLines: 2,
          ),
        ];

        final report = CoverageReport(files);
        final html = generator.generateIndex(report);

        expect(html, contains('#e74c3c')); // Red for < 60%
      });

      test('should handle empty report', () {
        final report = CoverageReport([]);
        final html = generator.generateIndex(report);

        expect(html, contains('0.0%'));
        expect(html, contains('0 / 0'));
        expect(html, contains('0'));
      });
    });

    group('generateFileDetail', () {
      test('should generate valid HTML for file details', () {
        final file = FileReport(
          path: 'lib/example.dart',
          lineHits: {1: 1, 2: 0},
          totalLines: 2,
          coveredLines: 1,
        );

        final report = CoverageReport([file]);
        final html = generator.generateFileDetail(file, report);

        expect(html, contains('<!DOCTYPE html>'));
        expect(html, contains('example.dart'));
        expect(html, contains('lib/example.dart'));
        expect(html, contains('50.0%'));
        expect(html, contains('Back to overview'));
      });

      test('should include legend', () {
        final file = FileReport(
          path: 'lib/example.dart',
          lineHits: {},
          totalLines: 0,
          coveredLines: 0,
        );

        final report = CoverageReport([file]);
        final html = generator.generateFileDetail(file, report);

        expect(html, contains('Covered'));
        expect(html, contains('Not Covered'));
        expect(html, contains('Not Tracked'));
      });

      test('should escape HTML characters in source code', () {
        final file = FileReport(
          path: 'test.dart',
          lineHits: {},
          totalLines: 0,
          coveredLines: 0,
        );

        final report = CoverageReport([file]);
        final html = generator.generateFileDetail(file, report);

        expect(html, contains('source-table'));
      });

      test('should apply correct CSS classes for coverage', () {
        final file = FileReport(
          path: 'lib/example.dart',
          lineHits: {1: 1, 2: 0, 3: 0},
          totalLines: 3,
          coveredLines: 1,
        );

        final report = CoverageReport([file]);
        final html = generator.generateFileDetail(file, report);

        expect(html, contains('line-covered'));
        expect(html, contains('line-not-covered'));
        expect(html, contains('line-not-tracked'));
      });
    });

    group('HTML escaping', () {
      test('should escape special HTML characters', () {
        final file = FileReport(
          path: 'lib/<script>alert("xss")</script>.dart',
          lineHits: {},
          totalLines: 0,
          coveredLines: 0,
        );

        final report = CoverageReport([file]);
        final html = generator.generateIndex(report);

        expect(html, contains('&lt;script&gt;'));
        expect(html, contains('&quot;xss&quot;'));
        expect(html, isNot(contains('<script>alert')));
      });

      test('should escape ampersands', () {
        final file = FileReport(
          path: 'lib/a&b.dart',
          lineHits: {},
          totalLines: 0,
          coveredLines: 0,
        );

        final report = CoverageReport([file]);
        final html = generator.generateIndex(report);

        expect(html, contains('a&amp;b.dart'));
      });
    });
  });
}
