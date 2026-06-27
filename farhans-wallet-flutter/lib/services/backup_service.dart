import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Exports/imports the whole wallet as a single JSON file so data can be moved
/// to another device or kept as a backup before uninstalling.
class BackupService {
  Future<void> exportAndShare(Map<String, dynamic> data) async {
    final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().split('T').first;
    final file = File('${dir.path}/pocketflow_backup_$stamp.json');
    await file.writeAsString(jsonStr);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      subject: 'Pocket Flow backup',
      text: 'Pocket Flow backup — open Pocket Flow on the other phone → Settings → '
          'Backup & restore → Import, and choose this file.',
    );
  }

  Future<Map<String, dynamic>?> pickAndRead() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final f = result.files.single;
    String content;
    if (f.bytes != null) {
      content = utf8.decode(f.bytes!);
    } else if (f.path != null) {
      content = await File(f.path!).readAsString();
    } else {
      return null;
    }
    final decoded = jsonDecode(content);
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  }
}
