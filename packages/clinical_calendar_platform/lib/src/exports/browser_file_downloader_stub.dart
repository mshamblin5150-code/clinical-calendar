import 'browser_file_downloader.dart';

BrowserFileDownloader createBrowserFileDownloader() =>
    const _UnsupportedBrowserFileDownloader();

final class _UnsupportedBrowserFileDownloader implements BrowserFileDownloader {
  const _UnsupportedBrowserFileDownloader();

  @override
  Future<void> download({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  }) => throw UnsupportedError('Browser downloads require a web runtime.');
}
