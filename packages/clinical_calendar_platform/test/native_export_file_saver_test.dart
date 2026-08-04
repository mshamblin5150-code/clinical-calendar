import 'dart:io';
import 'dart:typed_data';

import 'package:clinical_calendar_application/clinical_calendar_application.dart';
import 'package:clinical_calendar_platform/clinical_calendar_platform.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter_file_saver/flutter_file_saver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Windows cancellation is explicit and writes no bytes', () async {
    final platform = _FileSelectorFake();
    FileSelectorPlatform.instance = platform;

    final outcome = await NativeExportFileSaver(
      platform: NativeSavePlatform.windows,
    ).save(_request());

    expect(outcome, NativeFileSaveOutcome.cancelled);
    expect(platform.suggestedName, 'clinical-export.json');
    expect(platform.extensions, ['json']);
  });

  test('Windows saves exact bytes to selected system path', () async {
    final temporary = Directory.systemTemp.createTempSync('export-saver-');
    addTearDown(() => temporary.deleteSync(recursive: true));
    final destination = '${temporary.path}${Platform.pathSeparator}saved.json';
    final platform = _FileSelectorFake(destination: destination);
    FileSelectorPlatform.instance = platform;

    final outcome = await NativeExportFileSaver(
      platform: NativeSavePlatform.windows,
    ).save(_request());

    expect(outcome, NativeFileSaveOutcome.saved);
    expect(File(destination).readAsBytesSync(), [
      123,
      34,
      118,
      34,
      58,
      49,
      125,
    ]);
  });

  test('Android/iOS backend receives exact filename and bytes', () async {
    final platform = _MobileSaverFake();
    FlutterFileSaver().setFileSaverInstance(platform);

    final outcome = await NativeExportFileSaver(
      platform: NativeSavePlatform.android,
    ).save(_request());

    expect(outcome, NativeFileSaveOutcome.saved);
    expect(platform.fileName, 'clinical-export.json');
    expect(platform.bytes, [123, 34, 118, 34, 58, 49, 125]);
  });

  test('Android/iOS native dialog cancellation is explicit', () async {
    FlutterFileSaver().setFileSaverInstance(_MobileSaverFake(cancelled: true));

    final outcome = await NativeExportFileSaver(
      platform: NativeSavePlatform.ios,
    ).save(_request());

    expect(outcome, NativeFileSaveOutcome.cancelled);
  });
}

NativeFileSaveRequest _request() => NativeFileSaveRequest(
  suggestedFileName: 'clinical-export.json',
  mimeType: 'application/json',
  bytes: const [123, 34, 118, 34, 58, 49, 125],
);

final class _FileSelectorFake extends FileSelectorPlatform {
  _FileSelectorFake({this.destination});

  final String? destination;
  String? suggestedName;
  List<String>? extensions;

  @override
  Future<FileSaveLocation?> getSaveLocation({
    List<XTypeGroup>? acceptedTypeGroups,
    SaveDialogOptions options = const SaveDialogOptions(),
  }) async {
    suggestedName = options.suggestedName;
    extensions = acceptedTypeGroups!.single.extensions;
    return destination == null ? null : FileSaveLocation(destination!);
  }
}

final class _MobileSaverFake extends FileManagerPlatform {
  _MobileSaverFake({this.cancelled = false});

  final bool cancelled;
  String? fileName;
  List<int>? bytes;

  @override
  Future<String> writeFile({
    required String fileName,
    required Uint8List bytes,
  }) async {
    if (cancelled) throw FileSaverCancelledException();
    this.fileName = fileName;
    this.bytes = bytes;
    return 'content://selected/$fileName';
  }
}
