import 'dart:convert';
import 'dart:io';

import 'package:acervo/src/youtube/domain/youtube_video.dart';

class VideoCategory {
  const VideoCategory({
    required this.name,
    required this.playlist,
    required this.keywords,
  });

  final String name;
  final String playlist;
  final List<String> keywords;

  factory VideoCategory.fromJson(Map<String, Object?> json) {
    final name = json['name'] as String?;
    final playlist = json['playlist'] as String? ?? name;
    final keywords = (json['keywords'] as List<Object?>? ?? const [])
        .whereType<String>()
        .where((keyword) => keyword.trim().isNotEmpty)
        .toList(growable: false);

    if (name == null || name.trim().isEmpty) {
      throw const FormatException('Each category must have a non-empty name.');
    }
    if (playlist == null || playlist.trim().isEmpty) {
      throw FormatException('Category "$name" must have a playlist name.');
    }
    if (keywords.isEmpty) {
      throw FormatException('Category "$name" must have keywords.');
    }

    return VideoCategory(
      name: name.trim(),
      playlist: playlist.trim(),
      keywords: keywords.map((keyword) => keyword.toLowerCase()).toList(),
    );
  }
}

List<VideoCategory> loadVideoCategories(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map<String, Object?>) {
    throw const FormatException('The categories file must contain an object.');
  }
  final rawCategories = decoded['categories'];
  if (rawCategories is! List<Object?> || rawCategories.isEmpty) {
    throw const FormatException(
      'The categories file must contain a non-empty "categories" list.',
    );
  }

  return rawCategories
      .map((category) {
        if (category is! Map<String, Object?>) {
          throw const FormatException('Each category must be an object.');
        }
        return VideoCategory.fromJson(category);
      })
      .toList(growable: false);
}

Map<VideoCategory, List<YouTubeVideo>> categorizeVideos(
  Iterable<YouTubeVideo> videos,
  List<VideoCategory> categories,
) {
  final result = {
    for (final category in categories) category: <YouTubeVideo>[],
  };

  for (final video in videos) {
    final searchableText = [
      video.title,
      video.description,
      ...video.tags,
    ].join('\n').toLowerCase();

    for (final category in categories) {
      if (category.keywords.any(searchableText.contains)) {
        result[category]!.add(video);
        break;
      }
    }
  }

  return result;
}
