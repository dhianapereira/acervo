import 'package:acervo/src/youtube/domain/playlist_item.dart';

/// Returns playlist items ordered by the original video publication date.
List<YouTubePlaylistItem> sortByVideoPublicationDate(
  Iterable<YouTubePlaylistItem> items,
) {
  final sorted = items.toList()
    ..sort((a, b) {
      final dateComparison = a.videoPublishedAt.compareTo(b.videoPublishedAt);
      if (dateComparison != 0) {
        return dateComparison;
      }

      return a.position.compareTo(b.position);
    });

  return sorted;
}

/// Accepts either a raw playlist id or a YouTube playlist URL.
String extractYouTubePlaylistId(String input) {
  final uri = Uri.tryParse(input);
  if (uri == null || !uri.hasScheme) {
    return input;
  }

  final list = uri.queryParameters['list'];
  if (list == null || list.isEmpty) {
    throw const FormatException(
      'YouTube playlist URLs must include the "list" query parameter.',
    );
  }

  return list;
}
