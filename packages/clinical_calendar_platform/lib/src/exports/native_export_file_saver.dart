import 'dart:io';
import 'dart:typed_data';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';

enum NativeSavePlatform { windows, android, ios }

/// Saves bytes through the operating system's native save surface.
///
/// Windows uses the official Flutter `file_selector` save dialog. Android and
/// iOS 16+ use `flutter_file_saver`, whose native implementations use
/// `ACTION_CREATE_DOCUMENT` and `UIDocumentPickerViewController` respectively.
final class NativeExportFileSaver implements NativeByteFileSaver {
  NativeExportFileSaver({NativeSavePlatform? platform})
    : _platform = platform ?? _currentPlatform();

  final NativeSavePlatform _platform;

  @override
  Future<NativeFileSaveOutcome> save(NativeFileSaveRequest request) =>
      switch (_platform) {
        NativeSavePlatform.windows => _saveOnWindows(request),
        NativeSavePlatform.android ||
        NativeSavePlatform.ios => _saveOnMobile(request),
      };

  Future<NativeFileSaveOutcome> _saveOnWindows(
    NativeFileSaveRequest request,
  ) async {
    final extension = _extension(request.suggestedFileName);
    final location = await getSaveLocation(
      suggestedName: request.suggestedFileName,
      acceptedTypeGroups: [
        XTypeGroup(
          label: extension.isEmpty ? request.mimeType : extension.toUpperCase(),
          extensions: extension.isEmpty ? null : [extension],
        ),
      ],
    );
    if (location == null) return NativeFileSaveOutcome.cancelled;
    await XFile.fromData(
      Uint8List.fromList(request.bytes),
      name: request.suggestedFileName,
      mimeType: request.mimeType,
    ).saveTo(location.path);
    return NativeFileSaveOutcome.saved;
  }

  Future<NativeFileSaveOutcome> _saveOnMobile(
    NativeFileSaveRequest request,
  ) async {
    try {
      await FlutterFileSaver().writeFileAsBytes(
        fileName: request.suggestedFileName,
        bytes: Uint8List.fromList(request.bytes),
      );
      return NativeFileSaveOutcome.saved;
    } on FileSaverCancelledException {
      return NativeFileSaveOutcome.cancelled;
    }
  }
}

NativeSavePlatform _currentPlatform() {
  if (Platform.isWindows) return NativeSavePlatform.windows;
  if (Platform.isAndroid) return NativeSavePlatform.android;
  if (Platform.isIOS) return NativeSavePlatform.ios;
  throw UnsupportedError(
    'Native export saving is supported on Windows, Android, and iOS.',
  );
}

String _extension(String fileName) {
  final separator = fileName.lastIndexOf('.');
  if (separator < 0 || separator == fileName.length - 1) return '';
  return fileName.substring(separator + 1).toLowerCase();
}
