class CoverageReport {
  final List<FileReport> files;

  CoverageReport(this.files);

  int get totalLines => files.fold(0, (sum, f) => sum + f.totalLines);
  int get coveredLines => files.fold(0, (sum, f) => sum + f.coveredLines);

  double get coveragePercent {
    if (totalLines == 0) return 0;
    return (coveredLines / totalLines) * 100;
  }

  Map<String, List<FileReport>> get filesByFolder {
    final Map<String, List<FileReport>> grouped = {};

    for (final file in files) {
      final folder = _getFolder(file.path);
      grouped.putIfAbsent(folder, () => []).add(file);
    }

    return grouped;
  }

  FolderNode get folderTree {
    final root = FolderNode('root', '');

    for (final file in files) {
      final normalizedPath = file.path.replaceAll('\\', '/');
      final parts = normalizedPath.split('/');
      var currentNode = root;

      if (parts.length == 1) {
        root.files.add(file);
        continue;
      }

      for (var i = 0; i < parts.length - 1; i++) {
        final folderName = parts[i];
        final folderPath = parts.sublist(0, i + 1).join('/');

        currentNode = currentNode.getOrCreateChild(folderName, folderPath);
      }

      currentNode.files.add(file);
    }

    return root;
  }

  String _getFolder(String path) {
    final normalizedPath = path.replaceAll('\\', '/');
    final lastSlash = normalizedPath.lastIndexOf('/');
    return lastSlash == -1 ? '.' : normalizedPath.substring(0, lastSlash);
  }
}

class FolderNode {
  final String name;
  final String path;
  final Map<String, FolderNode> children = {};
  final List<FileReport> files = [];

  FolderNode(this.name, this.path);

  FolderNode getOrCreateChild(String name, String path) {
    return children.putIfAbsent(name, () => FolderNode(name, path));
  }

  int get totalLines {
    var total = files.fold(0, (sum, f) => sum + f.totalLines);
    for (final child in children.values) {
      total += child.totalLines;
    }
    return total;
  }

  int get coveredLines {
    var total = files.fold(0, (sum, f) => sum + f.coveredLines);
    for (final child in children.values) {
      total += child.coveredLines;
    }
    return total;
  }

  double get coveragePercent {
    if (totalLines == 0) return 0;
    return (coveredLines / totalLines) * 100;
  }

  bool get hasChildren => children.isNotEmpty;
  bool get hasFiles => files.isNotEmpty;
}

class FileReport {
  final String path;
  final Map<int, int> lineHits; // line number -> hit count
  final int totalLines;
  final int coveredLines;

  FileReport({
    required this.path,
    required this.lineHits,
    required this.totalLines,
    required this.coveredLines,
  });

  double get coveragePercent {
    if (totalLines == 0) return 0;
    return (coveredLines / totalLines) * 100;
  }

  String get fileName {
    final normalizedPath = path.replaceAll('\\', '/');
    return normalizedPath.split('/').last;
  }
}
