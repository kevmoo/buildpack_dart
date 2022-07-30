import 'dart:io';

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';

part 'buildpack.g.dart';

final _upTime = Stopwatch()..start();
final _agents = <String, int>{};
var _callCount = 0;

// Configure routes.
final _router = Router()
  ..get('/', _rootHandler)
  ..get('/echo/<message>', _echoHandler);

Response _rootHandler(Request req) {
  final agent = req.headers['user-agent'];
  if (agent != null) {
    _agents[agent] = (_agents[agent] ?? 0) + 1;
  }

  return Response.ok(
    '''
Hello, Cloud Run and Cloud Native Buildpacks!
Call count: ${++_callCount}
   Up time: ${_upTime.elapsed}

Dart bits:
  Dart version: ${Platform.version}
    Proc count: ${Platform.numberOfProcessors}

Request headers:
  ${req.headers.output}

ENVIRONMENT:
  ${Platform.environment.output}

AGENTS:
  ${_agents.output}
''',
  );
}

extension on Map<String, Object> {
  String get output {
    final longestKey = keys.fold<int>(
      0,
      (previousValue, element) =>
          element.length > previousValue ? element.length : previousValue,
    );

    return (entries.toList()
          ..sort((a, b) => compareAsciiLowerCase(a.key, b.key)))
        .map((e) => '${e.key.padRight(longestKey)} ${e.value}')
        .join('\n  ');
  }
}

Response _echoHandler(Request request) {
  final message = request.params['message'];
  return Response.ok('$message\n');
}

Future<HttpServer> run() async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline().addMiddleware(logRequests()).addHandler(_router);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
  return server;
}

@JsonSerializable()
class Bob {}
