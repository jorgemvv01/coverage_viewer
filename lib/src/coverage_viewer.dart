import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'package:coverage_viewer/src/models/coverage_report.dart';
import 'package:coverage_viewer/src/parser/lcov_parser.dart';
import 'package:coverage_viewer/src/generator/html_generator.dart';

class CoverageViewer {
  CoverageReport parseLcov(String content) {
    return LcovParser().parse(content);
  }

  Future<HttpServer> startServer(CoverageReport report, int port) async {
    final router = Router();
    final htmlGenerator = HtmlGenerator();

    router.get('/', (Request request) {
      final html = htmlGenerator.generateIndex(report);
      return Response.ok(html, headers: {'Content-Type': 'text/html'});
    });

    router.get('/file/<path|.*>', (Request request, String path) {
      final decodedPath = Uri.decodeComponent(path);

      try {
        final file = report.files.firstWhere(
          (f) => f.path == decodedPath,
        );

        final html = htmlGenerator.generateFileDetail(file, report);
        return Response.ok(html, headers: {'Content-Type': 'text/html'});
      } catch (e) {
        return Response.notFound('File not found: $decodedPath');
      }
    });

    final handler =
        const Pipeline().addMiddleware(logRequests()).addHandler(router.call);

    final server = await io.serve(handler, 'localhost', port);

    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', 'http://localhost:$port']);
      } else if (Platform.isMacOS) {
        await Process.run('open', ['http://localhost:$port']);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', ['http://localhost:$port']);
      }
    } catch (e) {
      print('Could not open browser automatically: $e');
    }

    return server;
  }
}
