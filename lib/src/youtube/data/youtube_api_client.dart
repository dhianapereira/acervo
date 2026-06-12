import 'dart:convert';

import 'package:acervo/src/youtube/domain/playlist_item.dart';
import 'package:http/http.dart' as http;

/// Thin wrapper around the YouTube Data API endpoints used by Acervo.
class YouTubeApiClient {
  YouTubeApiClient({required this.apiKey, http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final String apiKey;
  final http.Client _httpClient;

  /// Fetches every item from a playlist, following YouTube pagination.
  Future<List<YouTubePlaylistItem>> fetchPlaylistItems(
    String playlistId,
  ) async {
    final items = <YouTubePlaylistItem>[];
    String? pageToken;

    do {
      final queryParameters = {
        'part': 'snippet,contentDetails',
        'playlistId': playlistId,
        'maxResults': '50',
        'key': apiKey,
      };

      if (pageToken != null) {
        queryParameters['pageToken'] = pageToken;
      }

      final response = await _httpClient.get(
        Uri.https(
          'www.googleapis.com',
          '/youtube/v3/playlistItems',
          queryParameters,
        ),
      );

      final body = _decodeResponse(response);
      final pageItems = body['items'] as List<Object?>? ?? const [];
      items.addAll(
        pageItems.cast<Map<String, Object?>>().map(
          YouTubePlaylistItem.fromJson,
        ),
      );
      pageToken = body['nextPageToken'] as String?;
    } while (pageToken != null);

    return items;
  }

  /// Moves one playlist item to a new zero-based position.
  ///
  /// This endpoint requires OAuth. API keys can list public playlist data, but
  /// cannot modify a user's playlist.
  Future<void> updatePlaylistItemPosition({
    required YouTubePlaylistItem item,
    required int position,
    required String accessToken,
  }) async {
    final response = await _httpClient.put(
      Uri.https('www.googleapis.com', '/youtube/v3/playlistItems', {
        'part': 'snippet',
      }),
      headers: {
        'authorization': 'Bearer $accessToken',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'id': item.id,
        'snippet': {
          'playlistId': item.playlistId,
          'position': position,
          'resourceId': {'kind': 'youtube#video', 'videoId': item.videoId},
        },
      }),
    );

    _decodeResponse(response);
  }

  Map<String, Object?> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(response.body) as Map<String, Object?>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final error = decoded['error'] as Map<String, Object?>?;
    final message = error?['message'] as String?;
    throw YouTubeApiException(
      response.statusCode,
      message ?? 'The YouTube API returned an error without a message.',
    );
  }

  void close() {
    _httpClient.close();
  }
}

class YouTubeApiException implements Exception {
  const YouTubeApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'YouTubeApiException($statusCode): $message';
}
