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
}
