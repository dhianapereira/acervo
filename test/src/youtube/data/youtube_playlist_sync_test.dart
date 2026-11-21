import 'package:acervo/src/youtube/data/youtube_api_client.dart';
import 'package:acervo/src/youtube/data/youtube_playlist_sync.dart';
import 'package:acervo/src/youtube/domain/youtube_video.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('adds only videos not already in an existing playlist', () async {
    final insertedVideoIds = <String>[];
    final client = YouTubeApiClient(
      accessToken: 'token',
      httpClient: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            '{"items":[{"contentDetails":{"videoId":"existing"}}]}',
            200,
          );
        }
        insertedVideoIds.add(
          RegExp(r'"videoId":"([^"]+)"').firstMatch(request.body)!.group(1)!,
        );
        return http.Response('{}', 200);
      }),
    );
    final videos = [
      const YouTubeVideo(
        id: 'existing',
        title: 'Existing',
        description: '',
        tags: [],
      ),
      const YouTubeVideo(id: 'new', title: 'New', description: '', tags: []),
    ];

    final result = await syncPrivatePlaylist(
      client: client,
      playlistsByTitle: {'Destination': 'playlist-id'},
      title: 'Destination',
      description: 'Description',
      videos: videos,
    );

    expect(result.created, isFalse);
    expect(result.added, 1);
    expect(result.alreadyPresent, 1);
    expect(insertedVideoIds, ['new']);
  });
}
