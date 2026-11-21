class YouTubeVideo {
  const YouTubeVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
  });

  final String id;
  final String title;
  final String description;
  final List<String> tags;

  factory YouTubeVideo.fromJson(Map<String, Object?> json) {
    final snippet = json['snippet'] as Map<String, Object?>? ?? {};
    final rawTags = snippet['tags'] as List<Object?>? ?? const [];
    return YouTubeVideo(
      id: json['id'] as String,
      title: snippet['title'] as String? ?? '(untitled)',
      description: snippet['description'] as String? ?? '',
      tags: rawTags.whereType<String>().toList(growable: false),
    );
  }
}
