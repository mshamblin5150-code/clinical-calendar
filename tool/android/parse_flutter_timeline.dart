import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> arguments) async {
  if (arguments.length == 1 && arguments.single == '--self-test') {
    _runSelfTest();
    return;
  }
  if (arguments.isNotEmpty) {
    stderr.writeln('The timeline URI must be provided on stdin.');
    exitCode = 64;
    return;
  }
  final timelineInput = stdin.readLineSync();
  if (timelineInput == null || timelineInput.trim().isEmpty) {
    stderr.writeln('A timeline URI is required on stdin.');
    exitCode = 64;
    return;
  }
  final normalizedInput = timelineInput.replaceAll('\u0000', '');
  final uriStart = normalizedInput.indexOf('http://');
  if (uriStart < 0) {
    stderr.writeln('Timeline stdin did not contain a local HTTP URI.');
    exitCode = 64;
    return;
  }
  final timelineUri = normalizedInput.substring(uriStart).trim();

  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(timelineUri));
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      stderr.writeln(
        'Timeline request failed with HTTP ${response.statusCode}.',
      );
      exitCode = 1;
      return;
    }
    final payload =
        jsonDecode(await response.transform(utf8.decoder).join())
            as Map<String, dynamic>;
    stdout.write(jsonEncode(summarizeFlutterTimeline(payload)));
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  } finally {
    client.close(force: true);
  }
}

Map<String, dynamic> summarizeFlutterTimeline(Map<String, dynamic> payload) {
  final result = payload['result'] as Map<String, dynamic>?;
  final events = result?['traceEvents'] as List<dynamic>? ?? const [];
  final frameStarts = <String, num>{};
  final rasterStarts = <String, num>{};
  final frameDurationsMs = <double>[];
  final rasterDurationsMs = <double>[];
  for (final value in events) {
    final event = value as Map<String, dynamic>;
    final name = event['name'];
    final phase = event['ph'];
    final timestamp = event['ts'] as num?;
    if (timestamp == null) continue;

    if (name == 'Frame' && phase == 'b') {
      frameStarts['${event['id']}'] = timestamp;
    } else if (name == 'Frame' && phase == 'e') {
      final start = frameStarts.remove('${event['id']}');
      if (start != null) frameDurationsMs.add((timestamp - start) / 1000);
    } else if (name == 'GPURasterizer::Draw' && phase == 'B') {
      rasterStarts['${event['tid']}'] = timestamp;
    } else if (name == 'GPURasterizer::Draw' && phase == 'E') {
      final start = rasterStarts.remove('${event['tid']}');
      if (start != null) rasterDurationsMs.add((timestamp - start) / 1000);
    }
  }
  if (frameDurationsMs.isEmpty || rasterDurationsMs.isEmpty) {
    throw const FormatException(
      'Timeline contains no complete Flutter frame pairs.',
    );
  }
  return {
    'renderedFrames': frameDurationsMs.length,
    'uiThreadFrameTimeMsP95': _percentile(frameDurationsMs, 0.95),
    'rasterThreadFrameTimeMsP95': _percentile(rasterDurationsMs, 0.95),
  };
}

double _percentile(List<double> values, double percentile) {
  values.sort();
  final index = (percentile * values.length).ceil().clamp(1, values.length) - 1;
  return double.parse(values[index].toStringAsFixed(3));
}

void _runSelfTest() {
  final summary = summarizeFlutterTimeline({
    'result': {
      'traceEvents': [
        {'name': 'Frame', 'ph': 'b', 'id': 'a', 'ts': 0},
        {'name': 'Frame', 'ph': 'e', 'id': 'a', 'ts': 1000},
        {'name': 'Frame', 'ph': 'b', 'id': 'b', 'ts': 2000},
        {'name': 'Frame', 'ph': 'e', 'id': 'b', 'ts': 6000},
        {'name': 'GPURasterizer::Draw', 'ph': 'B', 'tid': 1, 'ts': 0},
        {'name': 'GPURasterizer::Draw', 'ph': 'E', 'tid': 1, 'ts': 2000},
        {'name': 'GPURasterizer::Draw', 'ph': 'B', 'tid': 1, 'ts': 3000},
        {'name': 'GPURasterizer::Draw', 'ph': 'E', 'tid': 1, 'ts': 8000},
      ],
    },
  });
  if (summary['renderedFrames'] != 2 ||
      summary['uiThreadFrameTimeMsP95'] != 4.0 ||
      summary['rasterThreadFrameTimeMsP95'] != 5.0) {
    throw StateError('Timeline pairing or percentile self-test failed.');
  }
  try {
    summarizeFlutterTimeline({
      'result': {'traceEvents': <Object>[]},
    });
    throw StateError('Malformed timeline self-test did not fail.');
  } on FormatException {
    stdout.writeln('Flutter timeline parser self-test passed.');
  }
}
