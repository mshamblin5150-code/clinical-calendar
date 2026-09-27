abstract interface class BrowserFileDownloader {
  Future<void> download({
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  });
}
