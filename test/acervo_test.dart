import 'dart:io';

import 'package:acervo/acervo.dart';
import 'package:acervo/src/youtube/data/youtube_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('loads dotenv values with shell environment precedence', () {
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

  test('extracts playlist id from a YouTube URL', () {
    expect(
      extractYouTubePlaylistId(
        'https://www.youtube.com/playlist?list=PL123&feature=shared',
      ),
      'PL123',
    );
  });

  test('extracts playlist id from a shell-escaped watch URL', () {
    expect(
      extractYouTubePlaylistId(
        r'https://www.youtube.com/watch\?v\=VIDEO_ID\&list\=PLAYLIST_ID',
      ),
      'PLAYLIST_ID',
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

  test('lists playlist items with OAuth', () async {
    final requests = <http.Request>[];
    final client = YouTubeApiClient(
      accessToken: 'access-token',
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response('{"items":[]}', 200);
      }),
    );

    await client.fetchPlaylistItems('playlist');

    expect(requests, hasLength(1));
    expect(requests.single.url.queryParameters.containsKey('key'), isFalse);
    expect(requests.single.headers['authorization'], 'Bearer access-token');
  });
}
