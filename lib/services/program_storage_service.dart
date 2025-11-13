import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProgramStorageService {
  static const _lastProgramKey = 'last_compiled_program_json';

  Future<void> saveToPrefs(Map<String, dynamic> program) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastProgramKey, jsonEncode(program));
  }

  Future<Map<String, dynamic>?> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastProgramKey);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> exportToFile(Map<String, dynamic> program) async {
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Program JSON',
      fileName: 'program.json',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (savePath == null) return;
    final file = File(savePath);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(program),
    );
  }

  Future<Map<String, dynamic>?> importFromFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return null;
    final content = utf8.decode(bytes);
    return jsonDecode(content) as Map<String, dynamic>;
  }
}

/// Shared single instance accessor for prefs where needed outside async flows.
class ProgramStorageServiceShared {
  static Future<SharedPreferences> get instance => SharedPreferences.getInstance();
}

