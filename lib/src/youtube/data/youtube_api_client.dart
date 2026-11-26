import 'dart:convert';

import 'package:acervo/src/youtube/domain/playlist_item.dart';
import 'package:acervo/src/youtube/domain/youtube_video.dart';
import 'package:http/http.dart' as http;

/// Thin wrapper around the YouTube Data API endpoints used by Acervo.
class YouTubeApiClient {
  YouTubeApiClient({
    required this.accessToken,
    http.Client? httpClient,
    Future<void> Function(Duration)? delay,
  }) : _httpClient = httpClient ?? http.Client(),
       _delay = delay ?? Future<void>.delayed;

  final String accessToken;
  final http.Client _httpClient;
  final Future<void> Function(Duration) _delay;

  /// Fetches all videos liked or disliked by the authenticated user.
  Future<List<YouTubeVideo>> fetchRatedVideos(String rating) async {
    if (rating != 'like' && rating != 'dislike') {
      throw ArgumentError.value(rating, 'rating', 'Must be like or dislike.');
    }

    final videos = <YouTubeVideo>[];
    String? pageToken;
    do {
      final queryParameters = {
        'part': 'snippet',
        'myRating': rating,
        'maxResults': '50',
        'pageToken': ?pageToken,
      };
      final response = await _httpClient.get(
        Uri.https('www.googleapis.com', '/youtube/v3/videos', queryParameters),
        headers: _authorizationHeaders(),
      );
      final body = _decodeResponse(response);
      final items = body['items'] as List<Object?>? ?? const [];
      videos.addAll(
        items.cast<Map<String, Object?>>().map(YouTubeVideo.fromJson),
      );
      pageToken = body['nextPageToken'] as String?;
    } while (pageToken != null);

    return videos;
  }

  /// Returns private playlists owned by the user, keyed by title.
  Future<Map<String, String>> fetchOwnedPrivatePlaylistsByTitle() async {
    final playlists = <String, String>{};
    String? pageToken;
    do {
      final queryParameters = {
        'part': 'snippet,status',
        'mine': 'true',
        'maxResults': '50',
        'pageToken': ?pageToken,
      };
      final response = await _httpClient.get(
        Uri.https(
          'www.googleapis.com',
          '/youtube/v3/playlists',
          queryParameters,
        ),
        headers: _authorizationHeaders(),
      );
      final body = _decodeResponse(response);
      final items = body['items'] as List<Object?>? ?? const [];
      for (final item in items.cast<Map<String, Object?>>()) {
        final snippet = item['snippet'] as Map<String, Object?>? ?? {};
        final status = item['status'] as Map<String, Object?>? ?? {};
        final title = snippet['title'] as String?;
        final id = item['id'] as String?;
        if (title != null &&
            id != null &&
            status['privacyStatus'] == 'private') {
          playlists.putIfAbsent(title, () => id);
        }
      }
      pageToken = body['nextPageToken'] as String?;
    } while (pageToken != null);
    return playlists;
  }

  Future<String> createPrivatePlaylist({
    required String title,
    required String description,
  }) async {
    final response = await _httpClient.post(
      Uri.https('www.googleapis.com', '/youtube/v3/playlists', {
        'part': 'snippet,status',
      }),
      headers: {..._authorizationHeaders(), 'content-type': 'application/json'},
      body: jsonEncode({
        'snippet': {'title': title, 'description': description},
        'status': {'privacyStatus': 'private'},
      }),
    );
    final body = _decodeResponse(response);
    return body['id'] as String;
  }

  Future<void> addVideoToPlaylist({
    required String playlistId,
    required String videoId,
  }) async {
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/playlistItems', {
      'part': 'snippet',
    });
    final headers = {
      ..._authorizationHeaders(),
      'content-type': 'application/json',
    };
    final body = jsonEncode({
      'snippet': {
        'playlistId': playlistId,
        'resourceId': {'kind': 'youtube#video', 'videoId': videoId},
      },
    });
    final response = await _sendWithConflictRetry(
      () => _httpClient.post(uri, headers: headers, body: body),
    );
    _decodeResponse(response);
  }

  Future<void> deletePlaylistItem(String playlistItemId) async {
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/playlistItems', {
      'id': playlistItemId,
    });
    final response = await _sendWithConflictRetry(
      () => _httpClient.delete(uri, headers: _authorizationHeaders()),
    );
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    _decodeResponse(response);
  }

  /// Fetches every item from a playlist, following YouTube pagination.
  ///
  /// The command uses OAuth for listing and updating so the same credential can
  /// handle public, unlisted, and private playlists owned by the user.
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
        headers: _authorizationHeaders(),
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

  Future<Set<String>> fetchPlaylistVideoIds(String playlistId) async {
    final videoIds = <String>{};
    String? pageToken;
    do {
      final queryParameters = {
        'part': 'contentDetails',
        'playlistId': playlistId,
        'maxResults': '50',
        'pageToken': ?pageToken,
      };
      final response = await _httpClient.get(
        Uri.https(
          'www.googleapis.com',
          '/youtube/v3/playlistItems',
          queryParameters,
        ),
        headers: _authorizationHeaders(),
      );
      final body = _decodeResponse(response);
      final items = body['items'] as List<Object?>? ?? const [];
      for (final item in items.cast<Map<String, Object?>>()) {
        final details = item['contentDetails'] as Map<String, Object?>? ?? {};
        final videoId = details['videoId'] as String?;
        if (videoId != null) videoIds.add(videoId);
      }
      pageToken = body['nextPageToken'] as String?;
    } while (pageToken != null);
    return videoIds;
  }

  /// Moves one playlist item to a new zero-based position.
  Future<void> updatePlaylistItemPosition({
    required YouTubePlaylistItem item,
    required int position,
  }) async {
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/playlistItems', {
      'part': 'snippet',
    });
    final headers = {
      ..._authorizationHeaders(),
      'content-type': 'application/json',
    };
    final body = jsonEncode({
      'id': item.id,
      'snippet': {
        'playlistId': item.playlistId,
        'position': position,
        'resourceId': {'kind': 'youtube#video', 'videoId': item.videoId},
      },
    });
    final response = await _sendWithConflictRetry(
      () => _httpClient.put(uri, headers: headers, body: body),
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
    final errors = error?['errors'] as List<Object?>?;
    final firstError = errors?.whereType<Map<String, Object?>>().firstOrNull;
    final reason = firstError?['reason'] as String?;
    throw YouTubeApiException(
      response.statusCode,
      message ?? 'The YouTube API returned an error without a message.',
      reason: reason,
    );
  }

  Future<http.Response> _sendWithConflictRetry(
    Future<http.Response> Function() send,
  ) async {
    const retryDelays = [
      Duration(milliseconds: 250),
      Duration(milliseconds: 500),
      Duration(seconds: 1),
    ];
    for (var attempt = 0; ; attempt += 1) {
      final response = await send();
      if (!_isAbortedConflict(response) || attempt == retryDelays.length) {
        return response;
      }
      await _delay(retryDelays[attempt]);
    }
  }

  bool _isAbortedConflict(http.Response response) {
    if (response.statusCode != 409) return false;
    try {
      final body = jsonDecode(response.body) as Map<String, Object?>;
      final error = body['error'] as Map<String, Object?>?;
      final message = error?['message'] as String?;
      return message?.toLowerCase() == 'the operation was aborted.';
    } on FormatException {
      return false;
    }
  }

  void close() {
    _httpClient.close();
  }

  Map<String, String> _authorizationHeaders() {
    return {'authorization': 'Bearer $accessToken'};
  }
}

class YouTubeApiException implements Exception {
  const YouTubeApiException(this.statusCode, this.message, {this.reason});

  final int statusCode;
  final String message;
  final String? reason;

  bool get isPlaylistItemDuplicate =>
      statusCode == 409 && reason == 'playlistItemDuplicate';

  @override
  String toString() =>
      'YouTubeApiException($statusCode${reason == null ? '' : ', $reason'}): '
      '$message';
}
