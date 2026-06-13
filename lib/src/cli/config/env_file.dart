import 'dart:io';

/// Updates simple KEY=VALUE entries in a dotenv file while preserving
/// unrelated lines.
class EnvFile {
  const EnvFile(this.path);

  final String path;

  void upsertAll(Map<String, String> values) {
    final file = File(path);
    final existing = file.existsSync() ? file.readAsLinesSync() : <String>[];
    final pending = Map<String, String>.of(values);
    final updated = <String>[];

    for (final line in existing) {
      final key = _parseKey(line);
      if (key != null && pending.containsKey(key)) {
        updated.add('$key=${pending.remove(key)}');
      } else {
        updated.add(line);
      }
    }

    if (updated.isNotEmpty && updated.last.trim().isNotEmpty) {
      updated.add('');
    }

    for (final entry in pending.entries) {
      updated.add('${entry.key}=${entry.value}');
    }

    file.writeAsStringSync('${updated.join('\n')}\n');
  }

  String? _parseKey(String line) {
    final match = RegExp(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=').firstMatch(line);
    return match?.group(1);
  }
}
