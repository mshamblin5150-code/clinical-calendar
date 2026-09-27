import 'package:clinical_calendar_application/clinical_calendar_application.dart';

import 'browser_file_downloader.dart';
import 'browser_file_downloader_stub.dart'
    if (dart.library.js_interop) 'browser_file_downloader_web.dart';

/// Saves export bytes with the browser's normal download behavior.
///
/// Safari on iPhone routes these downloads through its standard Files flow.
final class WebExportFileSaver implements ByteFileSaver {
  WebExportFileSaver({BrowserFileDownloader? downloader})
    : _downloader = downloader ?? createBrowserFileDownloader();

  final BrowserFileDownloader _downloader;

  @override
  Future<FileSaveOutcome> save(FileSaveRequest request) async {
    await _downloader.download(
      fileName: request.suggestedFileName,
      mimeType: request.mimeType,
      bytes: request.bytes,
    );
    return FileSaveOutcome.saved;
  }
}
