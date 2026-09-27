import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'browser_file_downloader.dart';

BrowserFileDownloader createBrowserFileDownloader() =>
    const _WebBrowserFileDownloader();

final class _WebBrowserFileDownloader implements BrowserFileDownloader {
  const _WebBrowserFileDownloader();

  @override
  Future<void> download({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  }) async {
    final blob = web.Blob(
      <web.BlobPart>[Uint8List.fromList(bytes).toJS].toJS,
      web.BlobPropertyBag(type: mimeType),
    );
    final objectUrl = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = objectUrl
      ..download = fileName
      ..style.display = 'none';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    await Future<void>.delayed(Duration.zero);
    web.URL.revokeObjectURL(objectUrl);
  }
}
