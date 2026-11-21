import 'dart:convert';
import 'dart:io';

import 'package:acervo/src/youtube/domain/youtube_video.dart';

class VideoCategory {
  const VideoCategory({
    required this.name,
    required this.playlist,
    required this.keywords,
    this.isDefault = false,
  });

  final String name;
  final String playlist;
  final List<String> keywords;
  final bool isDefault;

  factory VideoCategory.fromJson(Map<String, Object?> json) {
    final name = json['name'] as String?;
    final playlist = json['playlist'] as String? ?? name;
    final isDefault = json['default'] as bool? ?? false;
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
    if (keywords.isEmpty && !isDefault) {
      throw FormatException('Category "$name" must have keywords.');
    }

    return VideoCategory(
      name: name.trim(),
      playlist: playlist.trim(),
      keywords: keywords.map((keyword) => keyword.toLowerCase()).toList(),
      isDefault: isDefault,
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

  final categories = rawCategories
      .map((category) {
        if (category is! Map<String, Object?>) {
          throw const FormatException('Each category must be an object.');
        }
        return VideoCategory.fromJson(category);
      })
      .toList(growable: false);
  if (categories.where((category) => category.isDefault).length > 1) {
    throw const FormatException('Only one category can be the default.');
  }
  return categories;
}

Map<VideoCategory, List<YouTubeVideo>> categorizeVideos(
  Iterable<YouTubeVideo> videos,
  List<VideoCategory> categories,
) {
  final result = {
    for (final category in categories) category: <YouTubeVideo>[],
  };
  final defaultCategory = categories
      .where((category) => category.isDefault)
      .firstOrNull;

  for (final video in videos) {
    final searchableText = [
      video.title,
      video.description,
      ...video.tags,
    ].join('\n').toLowerCase();

    var matched = false;
    for (final category in categories.where(
      (category) => !category.isDefault,
    )) {
      if (category.keywords.any(searchableText.contains)) {
        result[category]!.add(video);
        matched = true;
        break;
      }
    }
    if (!matched && defaultCategory != null) {
      result[defaultCategory]!.add(video);
    }
  }

  return result;
}
