import 'dart:io';
import 'package:args/args.dart';
import 'package:coverage_viewer/src/coverage_viewer.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('input',
        abbr: 'i',
        defaultsTo: 'coverage/lcov.info',
        help: 'Path to lcov.info file')
    ..addOption('port',
        abbr: 'p', defaultsTo: '8080', help: 'Port for the web server')
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage');

  try {
    final results = parser.parse(arguments);

    if (results['help'] as bool) {
      print('Coverage viewer');
      print('Usage: coverage_viewer [options]');
      print(parser.usage);
      return;
    }

    final inputPath = results['input'] as String;
    final port = int.parse(results['port'] as String);

    final file = File(inputPath);
    if (!file.existsSync()) {
      print('Error: File not found: $inputPath');
      print('Please run: flutter test --coverage');
      exit(1);
    }

    print('Reading coverage from: $inputPath');
    final content = await file.readAsString();

    final viewer = CoverageViewer();
    final report = viewer.parseLcov(content);

    print('Total files: ${report.files.length}');
    print('Starting server on http://localhost:$port');
    print('Press Ctrl+C to stop');

    late HttpServer server;

    ProcessSignal.sigint.watch().listen((signal) async {
      print('\n\nShutting down gracefully...');
      await server.close(force: false);
      print('Server closed. Goodbye!');
      exit(0);
    });

    if (!Platform.isWindows) {
      ProcessSignal.sigterm.watch().listen((signal) async {
        print('\n\nShutting down gracefully...');
        await server.close(force: false);
        print('Server closed. Goodbye!');
        exit(0);
      });
    }

    server = await viewer.startServer(report, port);
  } catch (e) {
    print('Error: $e');
    exit(1);
  }
}
