@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_platform/clinical_calendar_web_platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web/web.dart' as web;

void main() {
  test('download MIME contract accepts only the expected type and charset', () {
    final csv = _downloadMimeType('text/csv; charset=utf-8');
    for (final value in [
      'text/csv',
      'text/csv; charset=utf-8',
      'TEXT/CSV; CHARSET=UTF-8',
      'text/csv;charset = utf-8',
    ]) {
      expect(value, csv);
    }
    for (final value in [
      'text/plain',
      'text/csv; charset=iso-8859-1',
      'text/csv; charset=',
      'text/csv; unexpected=value',
      'text/csv; charset=utf-8; unexpected=value',
      'text/csv; charset=utf-8; charset=utf-8',
      'text/csv;',
    ]) {
      expect(value, isNot(csv));
    }
    expect(
      'application/json',
      _downloadMimeType('application/json; charset=utf-8'),
    );
    expect(
      'application/json; charset=utf-8',
      _downloadMimeType('application/json; charset=utf-8'),
    );
    expect(
      'application/json; charset=ascii',
      isNot(_downloadMimeType('application/json; charset=utf-8')),
    );
    expect('application/pdf', _downloadMimeType('application/pdf'));
    expect(
      'application/pdf; charset=utf-8',
      isNot(_downloadMimeType('application/pdf')),
    );
  });

  test('real browser downloader accepts every export format', () async {
    final saver = WebExportFileSaver();
    final requests = [
      FileSaveRequest(
        suggestedFileName: 'placement-sentinel.pdf',
        mimeType: 'application/pdf',
        bytes: [37, 80, 68, 70, 45, 255],
      ),
      FileSaveRequest(
        suggestedFileName: 'placement-sentinel.csv',
        mimeType: 'text/csv; charset=utf-8',
        bytes: [0, 10, 13, 34, 44, 61, 255],
      ),
      FileSaveRequest(
        suggestedFileName: 'placement-sentinel.json',
        mimeType: 'application/json; charset=utf-8',
        bytes: [123, 34, 115, 101, 110, 116, 105, 110, 101, 108, 34, 125],
      ),
    ];

    for (final request in requests) {
      final capturedDownload = _captureNextDownload();
      expect(await saver.save(request), FileSaveOutcome.saved);
      final captured = await capturedDownload;
      expect(captured.fileName, request.suggestedFileName);
      // Browsers may retain or omit the requested UTF-8 charset parameter.
      expect(captured.mimeType, _downloadMimeType(request.mimeType));
      expect(captured.bytes, request.bytes);
    }
  });
}

Matcher _downloadMimeType(String requested) {
  final expected = requested.toLowerCase().split(';');
  return predicate<String>((actual) {
    final parts = actual.toLowerCase().split(';');
    if (parts.first.trim() != expected.first.trim()) return false;
    if (parts.length == 1) return true;
    if (parts.length != 2 || expected.length != 2) return false;
    final parameter = parts[1].split('=');
    return parameter.length == 2 &&
        parameter[0].trim() == 'charset' &&
        parameter[1].trim() == 'utf-8' &&
        expected[1].trim() == 'charset=utf-8';
  }, 'the requested media type with only its optional UTF-8 charset');
}

Future<_CapturedDownload> _captureNextDownload() {
  final completer = Completer<_CapturedDownload>();
  late web.EventListener listener;
  listener = ((web.Event event) {
    final target = event.target;
    if (target == null || !target.isA<web.HTMLAnchorElement>()) return;
    final anchor = target as web.HTMLAnchorElement;
    final fileName = anchor.download;
    final objectUrl = anchor.href;
    unawaited(() async {
      try {
        final response = await web.window.fetch(objectUrl.toJS).toDart;
        final blob = await response.blob().toDart;
        final buffer = (await blob.arrayBuffer().toDart).toDart;
        completer.complete(
          _CapturedDownload(
            fileName: fileName,
            mimeType: blob.type,
            bytes: buffer.asUint8List(),
          ),
        );
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    }());
  }).toJS;
  web.document.addEventListener('click', listener, true.toJS);
  return completer.future
      .timeout(const Duration(seconds: 10))
      .whenComplete(
        () => web.document.removeEventListener('click', listener, true.toJS),
      );
}

final class _CapturedDownload {
  const _CapturedDownload({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final List<int> bytes;
}
