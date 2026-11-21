import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:acervo/src/cli/config/environment.dart';
import 'package:acervo/src/youtube/data/youtube_access_token_resolver.dart';
import 'package:acervo/src/youtube/data/youtube_api_client.dart';
import 'package:acervo/src/youtube/data/youtube_oauth_client.dart';
import 'package:acervo/src/youtube/data/youtube_playlist_sync.dart';
import 'package:acervo/src/youtube/domain/video_category.dart';

class YouTubePlaylistCategorizeLikedCommand extends Command<int> {
  YouTubePlaylistCategorizeLikedCommand({required this.env}) {
    argParser
      ..addOption(
        'config',
        abbr: 'c',
        help: 'JSON file containing ordered category rules.',
        defaultsTo: 'youtube-categories.json',
      )
      ..addFlag(
        'apply',
        help: 'Create and update private category playlists.',
        negatable: false,
      )
      ..addOption(
        'env-file',
        help: 'Dotenv file to update when refreshing OAuth tokens.',
        defaultsTo: '.env',
      );
  }

  final Environment env;

  @override
  String get name => 'categorize-liked';

  @override
  String get description =>
      'Distributes liked videos into private playlists using local rules.';

  @override
  Future<int> run() async {
    final configPath = argResults!['config'] as String;
    final envFilePath = argResults!['env-file'] as String;
    final shouldApply = argResults!['apply'] as bool;
    late final List<VideoCategory> categories;
    try {
      categories = loadVideoCategories(configPath);
    } on FileSystemException catch (error) {
      stderr.writeln('Could not read $configPath: ${error.message}');
      return 66;
    } on FormatException catch (error) {
      stderr.writeln('Invalid categories file: ${error.message}');
      return 65;
    }

    final String? accessToken;
    try {
      accessToken = await resolveYouTubeAccessToken(
        env: env,
        envFilePath: envFilePath,
      );
    } on YouTubeOAuthException catch (error) {
      stderr.writeln(
        'Could not refresh YouTube authorization: ${error.message}',
      );
      stderr.writeln('Run "dart run acervo youtube auth" to authorize again.');
      return 70;
    }
    if (accessToken == null || accessToken.isEmpty) {
      usageException('Run "dart run acervo youtube auth" first.');
    }

    final client = YouTubeApiClient(accessToken: accessToken);
    try {
      final videos = await client.fetchRatedVideos('like');
      final categorized = categorizeVideos(videos, categories);
      final categorizedCount = categorized.values.fold<int>(
        0,
        (total, items) => total + items.length,
      );
      for (final entry in categorized.entries) {
        stdout.writeln(
          '${entry.key.name} -> "${entry.key.playlist}": '
          '${entry.value.length} video(s)',
        );
      }
      stdout.writeln(
        '${videos.length - categorizedCount} video(s) did not match any category.',
      );

      if (!shouldApply) {
        stdout.writeln('Dry run: use --apply to create and update playlists.');
        return 0;
      }

      final playlists = await client.fetchOwnedPrivatePlaylistsByTitle();
      for (final entry in categorized.entries) {
        if (entry.value.isEmpty) continue;
        final result = await syncPrivatePlaylist(
          client: client,
          playlistsByTitle: playlists,
          title: entry.key.playlist,
          description:
              'Liked videos in the ${entry.key.name} category, synchronized by Acervo.',
          videos: entry.value,
        );
        stdout.writeln(
          '"${entry.key.playlist}": ${result.added} added, '
          '${result.alreadyPresent} already present.',
        );
      }
      return 0;
    } on YouTubeApiException catch (error) {
      stderr.writeln(error);
      return 70;
    } finally {
      client.close();
    }
  }
}
