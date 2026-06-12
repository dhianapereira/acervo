import 'package:acervo/acervo.dart';
import 'package:test/test.dart';

void main() {
  group('extractYouTubePlaylistId - ', () {
    test('should extract playlist id when input is a YouTube playlist URL', () {
      expect(
        extractYouTubePlaylistId(
          'https://www.youtube.com/playlist?list=PL123&feature=shared',
        ),
        'PL123',
      );
    });

    test(
      'should extract playlist id when input is a shell-escaped watch URL',
      () {
        expect(
          extractYouTubePlaylistId(
            r'https://www.youtube.com/watch\?v\=VIDEO_ID\&list\=PLAYLIST_ID',
          ),
          'PLAYLIST_ID',
        );
      },
    );

    test('should keep playlist id unchanged when input is already an id', () {
      expect(extractYouTubePlaylistId('PL123'), 'PL123');
    });
  });

  group('sortByVideoPublicationDate - ', () {
    test(
      'should sort playlist items when comparing video publication dates',
      () {
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
      },
    );
  });
}
