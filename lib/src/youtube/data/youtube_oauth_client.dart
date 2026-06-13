import 'dart:convert';

import 'package:http/http.dart' as http;

const youtubePlaylistScope = 'https://www.googleapis.com/auth/youtube';

class YouTubeOAuthClient {
  YouTubeOAuthClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  Uri buildAuthorizationUrl({
    required String clientId,
    required String redirectUri,
    required String state,
    List<String> scopes = const [youtubePlaylistScope],
  }) {
    return Uri.https('accounts.google.com', '/o/oauth2/v2/auth', {
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': scopes.join(' '),
      'access_type': 'offline',
      'prompt': 'consent',
      'state': state,
    });
  }

  Future<OAuthTokenResponse> exchangeAuthorizationCode({
    required String clientId,
    required String clientSecret,
    required String redirectUri,
    required String code,
  }) {
    return _postToken({
      'client_id': clientId,
      'client_secret': clientSecret,
      'redirect_uri': redirectUri,
      'code': code,
      'grant_type': 'authorization_code',
    });
  }

  Future<OAuthTokenResponse> refreshAccessToken({
    required String clientId,
    required String clientSecret,
    required String refreshToken,
  }) {
    return _postToken({
      'client_id': clientId,
      'client_secret': clientSecret,
      'refresh_token': refreshToken,
      'grant_type': 'refresh_token',
    });
  }

  Future<OAuthTokenResponse> _postToken(Map<String, String> fields) async {
    final response = await _httpClient.post(
      Uri.https('oauth2.googleapis.com', '/token'),
      headers: {'content-type': 'application/x-www-form-urlencoded'},
      body: fields,
    );

    final decoded = jsonDecode(response.body) as Map<String, Object?>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return OAuthTokenResponse.fromJson(decoded);
    }

    final description =
        decoded['error_description'] as String? ?? decoded['error'] as String?;
    throw YouTubeOAuthException(
      response.statusCode,
      description ?? 'Google OAuth returned an error without a message.',
    );
  }

  void close() {
    _httpClient.close();
  }
}

class OAuthTokenResponse {
  const OAuthTokenResponse({
    required this.accessToken,
    this.refreshToken,
    this.expiresIn,
  });

  final String accessToken;
  final String? refreshToken;
  final int? expiresIn;

  factory OAuthTokenResponse.fromJson(Map<String, Object?> json) {
    final accessToken = json['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw const FormatException(
        'OAuth response did not include access_token.',
      );
    }

    return OAuthTokenResponse(
      accessToken: accessToken,
      refreshToken: json['refresh_token'] as String?,
      expiresIn: json['expires_in'] as int?,
    );
  }
}

class YouTubeOAuthException implements Exception {
  const YouTubeOAuthException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'YouTubeOAuthException($statusCode): $message';
}
