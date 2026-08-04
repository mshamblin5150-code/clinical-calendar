import 'package:file_selector/file_selector.dart' as file_selector;

/// Byte-oriented boundary for selecting an encrypted portable backup.
///
/// Returning bytes keeps Android content URIs and other platform-specific
/// locations out of the application composition root.
abstract interface class BackupByteFilePicker {
  Future<List<int>?> pickBackupBytes();
}

/// Injectable seam around the native file-selector dialog.
abstract interface class BackupFileSelectionGateway {
  Future<file_selector.XFile?> openFile({
    required List<file_selector.XTypeGroup> acceptedTypeGroups,
  });
}

/// Production gateway backed by Flutter's federated `file_selector` plugin.
final class FileSelectorBackupFileSelectionGateway
    implements BackupFileSelectionGateway {
  const FileSelectorBackupFileSelectionGateway();

  @override
  Future<file_selector.XFile?> openFile({
    required List<file_selector.XTypeGroup> acceptedTypeGroups,
  }) => file_selector.openFile(acceptedTypeGroups: acceptedTypeGroups);
}

/// Selects `.ccbackup` files on Windows, Android, and iOS and returns bytes.
///
/// [XFile.readAsBytes] is intentional: mobile document pickers may return a
/// content URI rather than a filesystem path.
final class NativeBackupFilePicker implements BackupByteFilePicker {
  NativeBackupFilePicker({BackupFileSelectionGateway? gateway})
    : _gateway = gateway ?? const FileSelectorBackupFileSelectionGateway();

  static const _backupType = file_selector.XTypeGroup(
    label: 'Clinical Calendar backup',
    extensions: ['ccbackup'],
  );

  final BackupFileSelectionGateway _gateway;

  @override
  Future<List<int>?> pickBackupBytes() async {
    final selected = await _gateway.openFile(
      acceptedTypeGroups: const [_backupType],
    );
    return selected?.readAsBytes();
  }
}
