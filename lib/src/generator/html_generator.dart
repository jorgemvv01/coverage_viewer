import 'dart:io';
import 'package:coverage_viewer/src/models/coverage_report.dart';
import 'package:intl/intl.dart';

class HtmlGenerator {
  String generateIndex(CoverageReport report) {
    final tree = report.folderTree;
    final treeHtml = _generateTreeHtml(tree, 0);

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Coverage report</title>
        <style>
          ${_getStyles()}
        </style>
      </head>
      <body>
        <div class="container">
          <header class="topbar">
            <div class="title">📊 Coverage report</div>
            <div class="top-controls">
              <input type="text" id="searchInput" class="top-search" placeholder="🔍 Search files..." onkeyup="filterFiles()">
            </div>
          </header>

          <div class="report-date" aria-hidden="true">Generated on: ${DateFormat('dd MMMM yyyy - HH:mm').format(DateTime.now().toLocal())}</div>

          <div class="summary" aria-hidden="false">
            <div class="summary-item card">
              <div class="summary-label">Total Coverage</div>
              <div class="summary-value coverage" style="background-color: ${_getCoverageColor(report.coveragePercent)};">
                ${report.coveragePercent.toStringAsFixed(1)}%
              </div>
            </div>
            <div class="summary-item card">
              <div class="summary-label">Lines Covered</div>
              <div class="summary-value">${report.coveredLines} / ${report.totalLines}</div>
            </div>
            <div class="summary-item card">
              <div class="summary-label">Files</div>
              <div class="summary-value">${report.files.length}</div>
            </div>
          </div>

          <button class="collapse-btn" onclick="collapseAllFolders()">
            🔽 Collapse all folders
          </button>

          <div class="tree-container" id="treeContainer">
            $treeHtml
          </div>
        </div>

        <script>
          function toggleFolder(element) {
            const content = element.nextElementSibling;
            const icon = element.querySelector('.folder-icon');
            if (!content) return;
            const isHidden = window.getComputedStyle(content).display === 'none';

            if (isHidden) {
              content.style.display = 'block';
              icon.textContent = '📂';
              element.classList.add('open');
            } else {
              content.style.display = 'none';
              icon.textContent = '📁';
              element.classList.remove('open');
            }
          }

          function collapseAllFolders() {  
            document.querySelectorAll('.folder-header.open').forEach(header => {
              header.classList.remove('open');
              
              const icon = header.querySelector('.folder-icon');
              if (icon) icon.textContent = '📁';
              
              const content = header.nextElementSibling;
              if (content && content.classList.contains('folder-content')) {
                content.style.display = 'none';
              }
            });
          }

          function filterFiles() {
            const input = document.getElementById('searchInput');
            const filter = input.value.toUpperCase();
            const items = document.querySelectorAll('.file-item, .folder-header');

            items.forEach(item => {
              const text = (item.dataset && item.dataset.search) ? item.dataset.search : (item.textContent || item.innerText);
              const matches = text.toUpperCase().indexOf(filter) > -1;
              item.style.display = matches ? '' : 'none';

              if (matches && item.classList.contains('file-item')) {
                let parent = item.closest('.folder-content');
                while (parent) {
                  parent.style.display = 'block';
                  const header = parent.previousElementSibling;
                  if (header && header.classList.contains('folder-header')) {
                    header.style.display = '';
                    header.classList.add('open');
                    const icon = header.querySelector('.folder-icon');
                    if (icon) icon.textContent = '📂';
                  }
                  parent = parent.parentElement.closest('.folder-content');
                }
              }
            });
          }

          document.addEventListener('DOMContentLoaded', function() {
            const firstFolder = document.querySelector('.folder-header');
            if (firstFolder) {
              toggleFolder(firstFolder);
            }
          });
        </script>
      </body>
      </html>
    ''';
  }

  String _generateTreeHtml(FolderNode node, int depth) {
    if (depth == 0) {
      final buffer = StringBuffer();

      final sortedChildren = node.children.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      for (final entry in sortedChildren) {
        buffer.write(_generateTreeHtml(entry.value, depth + 1));
      }

      final sortedFiles = List<FileReport>.from(node.files)
        ..sort((a, b) => a.fileName.compareTo(b.fileName));

      for (final file in sortedFiles) {
        final fileColor = _getCoverageColor(file.coveragePercent);
        final encodedPath = Uri.encodeComponent(file.path);

        buffer.write('''
          <div class="file-item" data-search="${_escapeHtml(file.fileName)} ${_escapeHtml(file.path)}">
            <span class="file-icon" aria-hidden="true">📄</span>
            <a href="/file/$encodedPath" class="file-link">${_escapeHtml(file.fileName)}</a>
            <span class="file-stats">
              <span class="stat-badge">${file.coveredLines}/${file.totalLines}</span>
              <span class="stat-badge coverage-badge" style="background-color: $fileColor;">
                ${file.coveragePercent.toStringAsFixed(1)}%
              </span>
            </span>
          </div>
        ''');
      }

      return buffer.toString();
    }

    final buffer = StringBuffer();
    final color = _getCoverageColor(node.coveragePercent);
    final hasContent = node.hasChildren || node.hasFiles;

    if (hasContent) {
      buffer.write('''
        <div class="folder-item">
          <div class="folder-header" onclick="toggleFolder(this)" role="button" tabindex="0">
            <span class="folder-icon" aria-hidden="true">📁</span>
            <span class="folder-name">${_escapeHtml(node.name)}</span>
            <span class="folder-stats">
              <span class="stat-badge">${node.coveredLines}/${node.totalLines}</span>
              <span class="stat-badge coverage-badge" style="background-color: $color;">
                ${node.coveragePercent.toStringAsFixed(1)}%
              </span>
            </span>
          </div>
          <div class="folder-content" style="display: none;">
      ''');

      final sortedChildren = node.children.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      for (final entry in sortedChildren) {
        buffer.write(_generateTreeHtml(entry.value, depth + 1));
      }

      final sortedFiles = List<FileReport>.from(node.files)
        ..sort((a, b) => a.fileName.compareTo(b.fileName));

      for (final file in sortedFiles) {
        final fileColor = _getCoverageColor(file.coveragePercent);
        final encodedPath = Uri.encodeComponent(file.path);

        buffer.write('''
          <div class="file-item" data-search="${_escapeHtml(file.fileName)} ${_escapeHtml(file.path)}">
            <span class="file-icon" aria-hidden="true">📄</span>
            <a href="/file/$encodedPath" class="file-link">${_escapeHtml(file.fileName)}</a>
            <span class="file-stats">
              <span class="stat-badge">${file.coveredLines}/${file.totalLines}</span>
              <span class="stat-badge coverage-badge" style="background-color: $fileColor;">
                ${file.coveragePercent.toStringAsFixed(1)}%
              </span>
            </span>
          </div>
        ''');
      }

      buffer.write('''
          </div>
        </div>
      ''');
    }

    return buffer.toString();
  }

  String generateFileDetail(FileReport file, CoverageReport report) {
    String? sourceCode;
    try {
      final sourceFile = File(file.path);
      if (sourceFile.existsSync()) {
        sourceCode = sourceFile.readAsStringSync();
      }
    } catch (e) {
      sourceCode = '// Error reading file: $e';
    }

    final lines = sourceCode?.split('\n') ?? [];
    final linesHtml = <String>[];

    for (int i = 0; i < lines.length; i++) {
      final lineNum = i + 1;
      final hits = file.lineHits[lineNum];
      String className = 'line-not-tracked';
      String hitsText = '';

      if (hits != null) {
        if (hits > 0) {
          className = 'line-covered';
          hitsText = '$hits×';
        } else {
          className = 'line-not-covered';
          hitsText = '0×';
        }
      }

      final escapedLine = _escapeHtml(lines[i]);
      linesHtml.add('''
        <tr class="$className">
          <td class="line-number">$lineNum</td>
          <td class="hit-count">$hitsText</td>
          <td class="source-code"><pre>$escapedLine</pre></td>
        </tr>
      ''');
    }

    return '''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>${file.fileName} - Coverage</title>
        <style>
          ${_getStyles()}
          ${_getFileDetailStyles()}
        </style>
      </head>
      <body>
        <div class="container file-detail">
          <a href="#" onclick="if (document.referrer) { history.back(); } else { window.location.href='/'; } return false;">
            ← Back to overview
          </a>
          
          <h1 class="file-title">📄 ${file.path}</h1>
          
          <div class="file-summary">
            <div class="summary-item">
              <div class="summary-label">Coverage</div>
              <div class="summary-value coverage" style="background-color: ${_getCoverageColor(file.coveragePercent)};">
                ${file.coveragePercent.toStringAsFixed(1)}%
              </div>
            </div>
            <div class="summary-item">
              <div class="summary-label">Lines Covered</div>
              <div class="summary-value">${file.coveredLines} / ${file.totalLines}</div>
            </div>
          </div>

          <div class="legend">
            <span class="legend-item"><span class="legend-box line-covered"></span> Covered</span>
            <span class="legend-item"><span class="legend-box line-not-covered"></span> Not Covered</span>
            <span class="legend-item"><span class="legend-box line-not-tracked"></span> Not Tracked</span>
          </div>

          <div class="code-wrapper">
            <table class="source-table" role="table">
              <tbody>
                ${linesHtml.join()}
              </tbody>
            </table>
          </div>
        </div>
      </body>
      </html>
    ''';
  }

  String _getCoverageColor(double percent) {
    if (percent >= 80) return '#2ecc71';
    if (percent >= 60) return '#f39c12';
    return '#e74c3c';
  }

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  String _getStyles() {
    return '''
      :root {
        --bg-grad-1: #f6f8fb;
        --bg-grad-2: #eef2ff;
        --card-bg: rgba(255,255,255,0.85);
        --muted: #6b7280;
        --accent: #4f46e5;
        --success: #2ecc71;
        --warning: #f39c12;
        --danger: #e74c3c;
        --glass: rgba(255,255,255,0.6);
        --radius: 12px;
        --shadow-1: 0 6px 18px rgba(16,24,40,0.08);
        --max-width: 1200px;
      }

      * { box-sizing: border-box; }
      html, body { height: 100%; }
      body {
        margin: 0;
        font-family: Inter, ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, "Helvetica Neue", Arial;
        background: linear-gradient(180deg, var(--bg-grad-2) 0%, var(--bg-grad-1) 100%);
        color: #111827;
        -webkit-font-smoothing:antialiased;
        -moz-osx-font-smoothing:grayscale;
        padding: 24px;
      }

      .container {
        max-width: var(--max-width);
        margin: 0 auto;
        background: linear-gradient(180deg, rgba(255,255,255,0.98), rgba(250,250,250,0.98));
        border-radius: 16px;
        padding: 24px;
        box-shadow: var(--shadow-1);
        min-height: calc(100vh - 48px);
        display: flex;
        height: 100%;
        flex-direction: column;
      }

      .topbar {
        display: flex;
        gap: 12px;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 18px;
      }

      .title {
        font-weight: 700;
        font-size: 1.25rem;
        display: flex;
        align-items: center;
        gap: 10px;
      }

      .report-date {
        font-size: 0.95rem;
        color: var(--text-secondary, #4b5563);
        font-weight: 400;
        margin-top: -6px;
        margin-bottom: 12px;
        letter-spacing: 0.2px;
        text-align: center;
        opacity: 0.85;
      }

      .top-controls { display:flex; gap:10px; align-items:center; }

      .top-search {
        max-width: 420px;
        width: 36vw;
        padding: 10px 14px;
        border-radius: 10px;
        border: 1px solid rgba(15,23,42,0.30);
        background: white;
        box-shadow: 0 1px 0 rgba(16,24,40,0.02) inset;
        font-size: 14px;
      }

      .summary {
        display: grid;
        grid-template-columns: repeat(3, minmax(0,1fr));
        gap: 16px;
        margin-bottom: 20px;
      }

      .card {
        background: var(--card-bg);
        border-radius: 12px;
        padding: 14px 18px;
        box-shadow: 0 4px 12px rgba(31,41,55,0.04);
        display: flex;
        flex-direction: column;
        gap: 8px;
      }

      .summary-label {
        font-size: 12px;
        color: var(--muted);
        text-transform: uppercase;
        letter-spacing: 0.6px;
        font-weight: 600;
      }

      .summary-value {
        font-size: 20px;
        font-weight: 700;
        padding: 8px 12px;
        border-radius: 999px;
        color: #0f172a;
        display: inline-block;
        background: transparent;
      }
      .summary-value.coverage {
        color: white;
      }

      .tree-container {
        background: transparent;
        border-radius: 12px;
        padding: 12px;
        height: 70vh;
        overflow-x: hidden;
        overflow-y: auto;
        flex: 1 1 auto;
      }

      .folder-item { margin-bottom: 8px; }

      .folder-header {
        display: flex;
        align-items: center;
        gap: 12px;
        padding: 10px 12px;
        border-radius: 10px;
        transition: transform 0.12s ease, background 0.12s ease;
        cursor: pointer;
        background: linear-gradient(180deg, rgba(255,255,255,0.6), rgba(250,250,250,0.6));
      }

      .folder-header:focus {
        outline: 3px solid rgba(79,70,229,0.12);
        outline-offset: 2px;
      }

      .folder-header:hover { transform: translateX(2px); }

      .folder-header.open { background: linear-gradient(90deg, rgba(79,70,229,0.06), rgba(255,255,255,0.6)); border-left: 4px solid var(--accent); }

      .folder-icon { font-size: 18px; width: 22px; text-align:center; }
      .folder-name { font-weight: 600; color: #0f172a; font-size: 14px; }

      .folder-stats { display:flex; gap:8px; align-items:center; }

      .stat-badge {
        font-size: 12px;
        padding: 6px 8px;
        border-radius: 999px;
        background: rgba(15,23,42,0.04);
        color: #111827;
        font-weight: 600;
      }

      .coverage-badge { color: white; }

      .folder-content { margin-left: 28px; padding-left: 12px; border-left: 1px dashed rgba(15,23,42,0.04); margin-top:8px; }

      .file-item {
        display:flex;
        align-items:center;
        gap:12px;
        padding: 8px 10px;
        border-radius: 8px;
        transition: background 0.12s ease, transform 0.08s ease;
      }

      .file-item:hover { background: rgba(15,23,42,0.02); transform: translateX(2px); }

      .file-icon { width:20px; text-align:center; }

      .file-link { text-decoration:none; color: var(--accent); font-weight:600; font-size: 13px; }
      .file-link:hover { text-decoration:underline; }

      .file-stats { margin-left: auto; display:flex; gap:8px; align-items:center; }

      .file-detail .file-title { font-size: 1rem; margin: 6px 0 14px 0; font-weight: 700; }

      @media (max-width: 900px) {
        :root { --max-width: 940px; }
        .summary { grid-template-columns: repeat(2, 1fr); }
        .top-search { width: 48vw; }
      }

      @media (max-width: 640px) {
        .container { padding: 16px; }
        .summary { grid-template-columns: 1fr; }
        .top-search { min-width: 140px; }
        .folder-content { margin-left: 16px; }
      }

      a { color: inherit; }

      .collapse-btn {
        background: linear-gradient(180deg, rgba(255,255,255,0.9), rgba(250,250,250,0.9));
        border: 1px solid rgba(15, 23, 42, 0.1);
        border-radius: var(--radius);
        color: var(--accent);
        font-weight: 600;
        font-size: 14px;
        padding: 10px 16px;
        cursor: pointer;
        transition: all 0.15s ease;
        box-shadow: 0 1px 2px rgba(16, 24, 40, 0.06);
        display: inline-flex;
        align-items: center;
        gap: 6px;
      }

      .collapse-btn:hover {
        background: linear-gradient(180deg, rgba(250,250,255,0.95), rgba(240,240,255,0.9));
        box-shadow: 0 2px 4px rgba(16, 24, 40, 0.08);
        transform: translateY(-1px);
      }

      .collapse-btn:active {
        transform: translateY(0);
        box-shadow: 0 1px 2px rgba(16, 24, 40, 0.06);
        background: linear-gradient(180deg, rgba(245,245,255,0.95), rgba(235,235,255,0.9));
      }

      .collapse-btn:focus {
        outline: none;
        box-shadow: 0 0 0 2px rgba(79,70,229,0.25);
      }

    ''';
  }

  String _getFileDetailStyles() {
    return '''
      .file-summary { display:flex; gap:12px; margin-bottom:16px; align-items:center; }

      .legend { display:flex; gap:12px; align-items:center; margin-bottom:12px; }
      .legend-item { display:flex; gap:8px; align-items:center; font-size:13px; color: var(--muted); }

      .legend-box { width:14px; height:14px; border-radius:4px; display:inline-block; }
      .legend-box.line-covered { background: rgba(46,204,113,0.16); box-shadow: inset 0 0 0 2px rgba(46,204,113,0.9); }
      .legend-box.line-not-covered { background: rgba(231,76,60,0.12); box-shadow: inset 0 0 0 2px rgba(231,76,60,0.9); }
      .legend-box.line-not-tracked { background: rgba(15,23,42,0.02); box-shadow: inset 0 0 0 1px rgba(15,23,42,0.06); }

      .code-wrapper { overflow:auto; border-radius:10px; border:1px solid rgba(15,23,42,0.04); }
      .source-table { width:100%; border-collapse:collapse; font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, "Roboto Mono", "Courier New", monospace; font-size:13px; }
      .source-table td { vertical-align: top; padding:6px 10px; }

      .line-number { width:64px; text-align:right; color: #9ca3af; background: rgba(255,255,255,0.6); border-right:1px solid rgba(15,23,42,0.03); font-weight:600; }
      .hit-count { width:56px; text-align:center; font-weight:700; color: #374151; }

      .source-code pre { margin:0; white-space: pre; }

      .line-covered { background: rgba(46,204,113,0.10); }
      .line-covered .hit-count { color: var(--success); }

      .line-not-covered { background: rgba(231,76,60,0.10); }
      .line-not-covered .hit-count { color: var(--danger); }

      .line-not-tracked { background: transparent; }

      @media (max-width: 800px) {
        .source-table td { padding:8px 12px; }
      }
    ''';
  }
}
