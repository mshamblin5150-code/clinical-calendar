import 'dart:typed_data';

import 'package:clinical_calendar_platform/clinical_calendar_platform.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('returns null when the native picker is cancelled', () async {
    final gateway = _BackupFileSelectionGatewayFake();

    final bytes = await NativeBackupFilePicker(
      gateway: gateway,
    ).pickBackupBytes();

    expect(bytes, isNull);
    expect(gateway.acceptedTypeGroups, hasLength(1));
    expect(gateway.acceptedTypeGroups.single.extensions, ['ccbackup']);
  });

  test('returns the exact bytes exposed by the selected XFile', () async {
    final gateway = _BackupFileSelectionGatewayFake(
      selected: XFile.fromData(
        Uint8List.fromList(const [0, 1, 2, 127, 128, 255]),
        name: 'portable.ccbackup',
      ),
    );

    final bytes = await NativeBackupFilePicker(
      gateway: gateway,
    ).pickBackupBytes();

    expect(bytes, [0, 1, 2, 127, 128, 255]);
    expect(gateway.openCount, 1);
  });
}

final class _BackupFileSelectionGatewayFake
    implements BackupFileSelectionGateway {
  _BackupFileSelectionGatewayFake({this.selected});

  final XFile? selected;
  var openCount = 0;
  List<XTypeGroup> acceptedTypeGroups = const [];

  @override
  Future<XFile?> openFile({
    required List<XTypeGroup> acceptedTypeGroups,
  }) async {
    openCount += 1;
    this.acceptedTypeGroups = acceptedTypeGroups;
    return selected;
  }
}
