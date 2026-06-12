import 'dart:io';

import 'package:acervo/acervo.dart';
import 'package:test/test.dart';

void main() {
  test('loads dotenv values with shell environment precedence', () {
    final directory = Directory.systemTemp.createTempSync('acervo_test_');
    final envFile = File('${directory.path}/.env')
      ..writeAsStringSync('YOUTUBE_API_KEY=from-dotenv\nOTHER=value\n');

    try {
      final environment = Environment.load(
        envFilePath: envFile.path,
        platformEnvironment: {'YOUTUBE_API_KEY': 'from-shell'},
      );

      expect(environment.get('YOUTUBE_API_KEY'), 'from-shell');
      expect(environment.get('OTHER'), 'value');
    } finally {
      directory.deleteSync(recursive: true);
    }
  });

  test('extracts playlist id from a YouTube URL', () {
    expect(
      extractYouTubePlaylistId(
        'https://www.youtube.com/playlist?list=PL123&feature=shared',
      ),
      'PL123',
    );
  });

  test('keeps plain playlist id unchanged', () {
    expect(extractYouTubePlaylistId('PL123'), 'PL123');
  });

  test('sorts playlist items by video publication date', () {
    final newer = YouTubePlaylistItem(
      id: 'playlist-item-1',
      playlistId: 'playlist',
      videoId: 'video-1',
      title: 'Newer',
      position: 0,
      videoPublishedAt: DateTime.utc(2024, 1, 1),
    );
    final older = YouTubePlaylistItem(
      id: 'playlist-item-2',
      playlistId: 'playlist',
      videoId: 'video-2',
      title: 'Older',
      position: 1,
      videoPublishedAt: DateTime.utc(2020, 1, 1),
    );

    expect(sortByVideoPublicationDate([newer, older]), [older, newer]);
  });
}
