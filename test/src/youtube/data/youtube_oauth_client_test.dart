import 'package:acervo/src/youtube/data/youtube_oauth_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  test('should build an authorization URL for offline YouTube access', () {
    final client = YouTubeOAuthClient();
    final url = client.buildAuthorizationUrl(
      clientId: 'client-id',
      redirectUri: 'http://localhost:53682/oauth2callback',
      state: 'state',
    );

    expect(url.host, 'accounts.google.com');
    expect(url.path, '/o/oauth2/v2/auth');
    expect(url.queryParameters['client_id'], 'client-id');
    expect(url.queryParameters['redirect_uri'], contains('localhost'));
    expect(url.queryParameters['scope'], youtubePlaylistScope);
    expect(url.queryParameters['access_type'], 'offline');
    expect(url.queryParameters['prompt'], 'consent');
    expect(url.queryParameters['state'], 'state');
  });

  test('should exchange an authorization code for tokens', () async {
    late http.Request sentRequest;
    final client = YouTubeOAuthClient(
      httpClient: MockClient((request) async {
        sentRequest = request;
        return http.Response(
          '{"access_token":"access","refresh_token":"refresh","expires_in":3599}',
          200,
        );
      }),
    );

    final token = await client.exchangeAuthorizationCode(
      clientId: 'client-id',
      clientSecret: 'secret',
      redirectUri: 'http://localhost:53682/oauth2callback',
      code: 'code',
    );

    expect(sentRequest.url.toString(), 'https://oauth2.googleapis.com/token');
    expect(sentRequest.bodyFields['grant_type'], 'authorization_code');
    expect(sentRequest.bodyFields['client_id'], 'client-id');
    expect(sentRequest.bodyFields['client_secret'], 'secret');
    expect(sentRequest.bodyFields['code'], 'code');
    expect(token.accessToken, 'access');
    expect(token.refreshToken, 'refresh');
    expect(token.expiresIn, 3599);
  });

  test('should refresh access tokens', () async {
    late http.Request sentRequest;
    final client = YouTubeOAuthClient(
      httpClient: MockClient((request) async {
        sentRequest = request;
        return http.Response('{"access_token":"fresh"}', 200);
      }),
    );

    final token = await client.refreshAccessToken(
      clientId: 'client-id',
      clientSecret: 'secret',
      refreshToken: 'refresh',
    );

    expect(sentRequest.bodyFields['grant_type'], 'refresh_token');
    expect(sentRequest.bodyFields['refresh_token'], 'refresh');
    expect(token.accessToken, 'fresh');
  });
}
