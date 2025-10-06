import 'package:coverage_viewer/src/models/coverage_report.dart';

class LcovParser {
  CoverageReport parse(String content) {
    final files = <FileReport>[];
    final lines = content.split('\n');

    String? currentFile;
    Map<int, int> currentHits = {};
    int linesFound = 0;
    int linesHit = 0;

    for (final line in lines) {
      final trimmedLine = line.trim();

      if (trimmedLine.startsWith('SF:')) {
        currentFile = trimmedLine.substring(3).trim();
        currentHits = {};
        linesFound = 0;
        linesHit = 0;
      } else if (trimmedLine.startsWith('DA:')) {
        final parts = trimmedLine.substring(3).split(',');
        if (parts.length >= 2) {
          final lineNum = int.tryParse(parts[0]);
          final hits = int.tryParse(parts[1]);
          if (lineNum != null && hits != null) {
            currentHits[lineNum] = hits;
          }
        }
      } else if (trimmedLine.startsWith('LF:')) {
        linesFound = int.tryParse(trimmedLine.substring(3)) ?? 0;
      } else if (trimmedLine.startsWith('LH:')) {
        linesHit = int.tryParse(trimmedLine.substring(3)) ?? 0;
      } else if (trimmedLine == 'end_of_record' && currentFile != null) {
        files.add(FileReport(
          path: currentFile,
          lineHits: Map.from(currentHits),
          totalLines: linesFound,
          coveredLines: linesHit,
        ));
        currentFile = null;
      }
    }

    return CoverageReport(files);
  }
}
