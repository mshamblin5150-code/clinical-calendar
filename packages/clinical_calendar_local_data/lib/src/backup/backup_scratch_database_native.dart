import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart';

CommonDatabase openBackupScratchDatabase() => sqlite3.openInMemory();
