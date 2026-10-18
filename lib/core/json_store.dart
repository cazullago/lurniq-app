import 'dart:convert';
import 'dart:io';

/// Persistence abstraction. [FileJsonBox] is used on device; [MemoryJsonBox]
/// is used by widget tests (real async file IO deadlocks inside
/// testWidgets' FakeAsync zone, so tests must not touch the disk).
abstract class JsonBox {
  Future<Map<String, dynamic>> readMap();
  Future<void> writeMap(Map<String, dynamic> data);
  Future<void> delete();
}

/// File-backed box. Writes go through a temp file + rename so a crash
/// mid-write never corrupts the database.
class FileJsonBox implements JsonBox {
  FileJsonBox(this.file);
  final File file;

  @override
  Future<Map<String, dynamic>> readMap() async {
    try {
      if (!await file.exists()) return {};
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  @override
  Future<void> writeMap(Map<String, dynamic> data) async {
    await file.parent.create(recursive: true);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(data));
    await tmp.rename(file.path);
  }

  @override
  Future<void> delete() async {
    try {
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}

/// In-memory box for widget tests.
class MemoryJsonBox implements JsonBox {
  Map<String, dynamic> _data = {};

  @override
  Future<Map<String, dynamic>> readMap() async => _data;

  @override
  Future<void> writeMap(Map<String, dynamic> data) async {
    _data = data;
  }

  @override
  Future<void> delete() async {
    _data = {};
  }
}
