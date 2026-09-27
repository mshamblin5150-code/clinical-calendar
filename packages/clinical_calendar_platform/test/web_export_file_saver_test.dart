import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_platform/clinical_calendar_web_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
    test('browser download preserves ${request.suggestedFileName}', () async {
      final downloader = _BrowserFileDownloaderFake();
      final saver = WebExportFileSaver(downloader: downloader);

      final outcome = await saver.save(request);

      expect(outcome, FileSaveOutcome.saved);
      expect(downloader.fileName, request.suggestedFileName);
      expect(downloader.mimeType, request.mimeType);
      expect(downloader.bytes, request.bytes);
    });
  }
}

final class _BrowserFileDownloaderFake implements BrowserFileDownloader {
  String? fileName;
  String? mimeType;
  List<int>? bytes;

  @override
  Future<void> download({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  }) async {
    this.fileName = fileName;
    this.mimeType = mimeType;
    this.bytes = List<int>.of(bytes);
  }
}
