class YouTubePlaylistItem {
  const YouTubePlaylistItem({
    required this.id,
    required this.playlistId,
    required this.videoId,
    required this.title,
    required this.position,
    required this.videoPublishedAt,
  });

  final String id;
  final String playlistId;
  final String videoId;
  final String title;
  final int position;

  /// The video's original publication date on YouTube.
  ///
  /// This is different from `snippet.publishedAt`, which means "when this item
  /// was added to the playlist".
  final DateTime videoPublishedAt;

  factory YouTubePlaylistItem.fromJson(Map<String, Object?> json) {
    final snippet = json['snippet'] as Map<String, Object?>? ?? {};
    final contentDetails =
        json['contentDetails'] as Map<String, Object?>? ?? {};
    final resourceId = snippet['resourceId'] as Map<String, Object?>? ?? {};

    return YouTubePlaylistItem(
      id: json['id'] as String,
      playlistId: snippet['playlistId'] as String,
      videoId:
          (contentDetails['videoId'] as String?) ??
          (resourceId['videoId'] as String),
      title: snippet['title'] as String? ?? '(untitled)',
      position: snippet['position'] as int? ?? 0,
      videoPublishedAt: DateTime.parse(
        contentDetails['videoPublishedAt'] as String,
      ),
    );
  }
}
