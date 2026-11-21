import 'package:acervo/src/youtube/domain/video_category.dart';
import 'package:acervo/src/youtube/domain/youtube_video.dart';
import 'package:test/test.dart';

void main() {
  test('assigns a video only to the first matching category', () {
    final first = VideoCategory(
      name: 'Development',
      playlist: 'Development',
      keywords: const ['dart'],
    );
    final second = VideoCategory(
      name: 'Mobile',
      playlist: 'Mobile',
      keywords: const ['flutter'],
    );
    final video = YouTubeVideo(
      id: 'video-1',
      title: 'Build apps with Dart and Flutter',
      description: '',
      tags: const [],
    );

    final result = categorizeVideos([video], [first, second]);

    expect(result[first], [video]);
    expect(result[second], isEmpty);
  });

  test(
    'matches keywords against title, description, and tags ignoring case',
    () {
      final category = VideoCategory(
        name: 'Music',
        playlist: 'Music',
        keywords: const ['music'],
      );
      final videos = [
        const YouTubeVideo(
          id: 'title',
          title: 'MUSIC theory',
          description: '',
          tags: [],
        ),
        const YouTubeVideo(
          id: 'description',
          title: 'Lesson',
          description: 'A music lesson',
          tags: [],
        ),
        const YouTubeVideo(
          id: 'tag',
          title: 'Lesson',
          description: '',
          tags: ['Music'],
        ),
      ];

      expect(categorizeVideos(videos, [category])[category], videos);
    },
  );

  test('assigns unmatched videos to the default category', () {
    final music = VideoCategory(
      name: 'Music',
      playlist: 'Music',
      keywords: const ['music'],
    );
    final fallback = VideoCategory(
      name: 'Other',
      playlist: 'Other',
      keywords: const [],
      isDefault: true,
    );
    const video = YouTubeVideo(
      id: 'video-1',
      title: 'Unrelated subject',
      description: '',
      tags: [],
    );

    final result = categorizeVideos([video], [fallback, music]);

    expect(result[music], isEmpty);
    expect(result[fallback], [video]);
  });
}
