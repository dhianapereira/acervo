import 'dart:io';

import 'package:acervo/acervo.dart';
import 'package:test/test.dart';

void main() {
  test('should prefer shell environment when dotenv has same key', () {
    final directory = Directory.systemTemp.createTempSync('acervo_test_');
    final envFile = File('${directory.path}/.env')
      ..writeAsStringSync('YOUTUBE_ACCESS_TOKEN=from-dotenv\nOTHER=value\n');

    try {
      final environment = Environment.load(
        envFilePath: envFile.path,
        platformEnvironment: {'YOUTUBE_ACCESS_TOKEN': 'from-shell'},
      );

      expect(environment.get('YOUTUBE_ACCESS_TOKEN'), 'from-shell');
      expect(environment.get('OTHER'), 'value');
    } finally {
      directory.deleteSync(recursive: true);
    }
  });
}
