import 'package:acervo/src/youtube/data/youtube_api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('should use OAuth authorization when listing playlist items', () async {
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

  test('fetches rated videos and follows pagination', () async {
    var calls = 0;
    final client = YouTubeApiClient(
      accessToken: 'token',
      httpClient: MockClient((request) async {
        calls += 1;
        expect(request.url.queryParameters['myRating'], 'dislike');
        if (calls == 1) {
          return http.Response(
            '{"nextPageToken":"next","items":[{"id":"one",'
            '"snippet":{"title":"One","description":"Desc",'
            '"tags":["tag"]}}]}',
            200,
          );
        }
        expect(request.url.queryParameters['pageToken'], 'next');
        return http.Response(
          '{"items":[{"id":"two","snippet":{"title":"Two"}}]}',
          200,
        );
      }),
    );

    final videos = await client.fetchRatedVideos('dislike');

    expect(videos.map((video) => video.id), ['one', 'two']);
    expect(videos.first.tags, ['tag']);
    expect(calls, 2);
  });

  test('creates playlists as private', () async {
    late http.Request sentRequest;
    final client = YouTubeApiClient(
      accessToken: 'token',
      httpClient: MockClient((request) async {
        sentRequest = request;
        return http.Response('{"id":"playlist-id"}', 200);
      }),
    );

    final id = await client.createPrivatePlaylist(
      title: 'Category',
      description: 'Description',
    );

    expect(id, 'playlist-id');
    expect(sentRequest.method, 'POST');
    expect(sentRequest.url.path, '/youtube/v3/playlists');
    expect(sentRequest.body, contains('"privacyStatus":"private"'));
  });

  test('adds a video to a playlist', () async {
    late http.Request sentRequest;
    final client = YouTubeApiClient(
      accessToken: 'token',
      httpClient: MockClient((request) async {
        sentRequest = request;
        return http.Response('{}', 200);
      }),
    );

    await client.addVideoToPlaylist(
      playlistId: 'playlist-id',
      videoId: 'video-id',
    );

    expect(sentRequest.method, 'POST');
    expect(sentRequest.url.path, '/youtube/v3/playlistItems');
    expect(sentRequest.body, contains('"playlistId":"playlist-id"'));
    expect(sentRequest.body, contains('"videoId":"video-id"'));
  });

  test('deletes a playlist item', () async {
    late http.Request sentRequest;
    final client = YouTubeApiClient(
      accessToken: 'token',
      httpClient: MockClient((request) async {
        sentRequest = request;
        return http.Response('', 204);
      }),
    );

    await client.deletePlaylistItem('playlist-item-id');

    expect(sentRequest.method, 'DELETE');
    expect(sentRequest.url.path, '/youtube/v3/playlistItems');
    expect(sentRequest.url.queryParameters['id'], 'playlist-item-id');
  });

  test('retries an aborted playlist mutation conflict', () async {
    var calls = 0;
    final delays = <Duration>[];
    final client = YouTubeApiClient(
      accessToken: 'token',
      delay: (duration) async => delays.add(duration),
      httpClient: MockClient((request) async {
        calls += 1;
        if (calls < 3) {
          return http.Response(
            '{"error":{"message":"The operation was aborted."}}',
            409,
          );
        }
        return http.Response('', 204);
      }),
    );

    await client.deletePlaylistItem('playlist-item-id');

    expect(calls, 3);
    expect(delays, const [
      Duration(milliseconds: 250),
      Duration(milliseconds: 500),
    ]);
  });

  test('includes the API reason when formatting an error', () {
    const error = YouTubeApiException(409, 'Conflict', reason: 'aborted');

    expect(error.toString(), 'YouTubeApiException(409, aborted): Conflict');
  });
}
