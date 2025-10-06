# Coverage viewer

[![pub package](https://img.shields.io/pub/v/coverage_viewer.svg)](https://pub.dev/packages/coverage_viewer)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A beautiful and modern web-based coverage report viewer for Dart and Flutter projects. Transform your LCOV coverage reports into an interactive, hierarchical visualization with search capabilities and detailed line-by-line analysis.

##  Demo:
<img src="https://github.com/jorgemvv01/coverage_viewer/raw/main/resources/01.png" alt="Demo coverage viewer home"/>
<img src="https://github.com/jorgemvv01/coverage_viewer/raw/main/resources/02.png" alt="Demo coverage viewer detail"/>

## Features

- **Interactive web interface** - Browse coverage reports in your browser with a modern, responsive design
- **Hierarchical folder structure** - Navigate through your project structure with expandable/collapsible folders
- **Search functionality** - Quickly find files with instant search filtering
- **Color-coded coverage** - Visual indicators for coverage levels (green ≥80%, orange 60-79%, red <60%)
- **Line-by-line details** - See exactly which lines are covered, not covered, or not tracked
- **Cross-platform** - Works on Windows, macOS, and Linux
- **Auto-launch browser** - Automatically opens the report in your default browser

## Installation

### Global Installation (Recommended)

```bash
dart pub global activate coverage_viewer
```

### Or as a dev dependency

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  coverage_viewer: ^0.0.1
```

Then run:

```bash
dart pub get
```

## Usage

### For Flutter projects

```bash
# Generate coverage
flutter test --coverage

# View coverage report
coverage_viewer
```

### For Dart projects

```bash
# Generate coverage
dart test --coverage=coverage

# Convert to LCOV format
dart run coverage:format_coverage --lcov --in=coverage --out=coverage/lcov.info --packages=.dart_tool/package_config.json --report-on=lib

# View coverage report
coverage_viewer
```

### Custom options

```bash
# Custom input file
coverage_viewer --input path/to/custom.lcov

# Custom port
coverage_viewer --port 9000

# Combined options
_coverage_viewer --input coverage/lcov.info --port 3000

# Show help
coverage_viewer --help
```

### As a dev dependency

If installed as a dev dependency, run it with:

```bash
dart run coverage_viewer
```

## Command Line Options

| Option | Short | Default | Description |
|--------|-------|---------|-------------|
| `--input` | `-i` | `coverage/lcov.info` | Path to LCOV coverage file |
| `--port` | `-p` | `8080` | Port for the web server |
| `--help` | `-h` | - | Show usage information |

## Programmatic usage

You can also use the package programmatically in your Dart code:

```dart
import 'package:coverage_viewer/coverage_viewer.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final content = await rootBundle.loadString('coverage/lcov.info');
  
  // Parse coverage
  final viewer = CoverageViewer();
  final report = viewer.parseLcov(content);
  
  // Print statistics
  print('Total files: ${report.files.length}');
  print('Coverage: ${report.coveragePercent.toStringAsFixed(1)}%');
  print('Lines covered: ${report.coveredLines}/${report.totalLines}');
}
```

## Interface Features

### Main View
- **Total Coverage** - Overall coverage percentage with color indicator
- **Lines Covered** - Fraction of covered lines
- **File Count** - Number of tracked files
- **Search Bar** - Filter files by name or path
- **Collapse All** - Button to collapse all folder trees
- **Folder Tree** - Hierarchical view of your project structure

### File Detail View
- **Back Navigation** - Return to overview while preserving folder state
- **Coverage Percentage** - File-specific coverage
- **Line Numbers** - Every line numbered for easy reference
- **Hit Counts** - Number of times each line was executed
- **Color Coding**:
  - Green background: Covered lines
  - Red background: Uncovered lines
  - White background: Lines not tracked for coverage

## Requirements

- Dart SDK ≥3.0.0
- A generated LCOV coverage file

## Platform Support

| Platform | Supported | Auto-launch Browser |
|----------|-----------|---------------------|
| Windows | ✓ | ✓ |
| macOS | ✓ | ✓ |
| Linux | ✓ | ✓ |

## Example output

When you run `coverage_viewer`, you'll see:

```
Reading coverage from: coverage/lcov.info
Total files: 42
Starting server on http://localhost:8080
Press Ctrl+C to stop
```

The web interface will automatically open in your default browser.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Development

```bash
# Clone the repository
git clone https://github.com/jorgemvv01/coverage_viewer.git
cd coverage_viewer

# Install dependencies
dart pub get

# Run tests
dart test

# Run analyzer
dart analyze

# Format code
dart format .
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.

## Author

[Jorge Villarreal](https://www.linkedin.com/in/jorgemvv01/)

## Support

If you find this package useful, please consider:
- Giving it a star on [GitHub](https://github.com/jorgemvv01/coverage_viewer)
- Filing issues and feature requests
- Contributing to the codebase
