import 'dart:io';

import 'package:acervo/src/cli/config/env_file.dart';
import 'package:test/test.dart';

void main() {
  test('should update existing keys and append new keys', () {
    final directory = Directory.systemTemp.createTempSync('acervo_env_test_');
    final envFile = File('${directory.path}/.env')
      ..writeAsStringSync(
        'OTHER=value\n'
        'YOUTUBE_ACCESS_TOKEN=old-token\n',
      );

    try {
      EnvFile(envFile.path).upsertAll({
        'YOUTUBE_ACCESS_TOKEN': 'new-token',
        'YOUTUBE_REFRESH_TOKEN': 'refresh-token',
      });

      expect(
        envFile.readAsStringSync(),
        'OTHER=value\n'
        'YOUTUBE_ACCESS_TOKEN=new-token\n'
        '\n'
        'YOUTUBE_REFRESH_TOKEN=refresh-token\n',
      );
    } finally {
      directory.deleteSync(recursive: true);
    }
  });
}
