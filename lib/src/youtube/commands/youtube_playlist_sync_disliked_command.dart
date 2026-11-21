import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:acervo/src/cli/config/environment.dart';
import 'package:acervo/src/youtube/data/youtube_access_token_resolver.dart';
import 'package:acervo/src/youtube/data/youtube_api_client.dart';
import 'package:acervo/src/youtube/data/youtube_oauth_client.dart';
import 'package:acervo/src/youtube/data/youtube_playlist_sync.dart';

class YouTubePlaylistSyncDislikedCommand extends Command<int> {
  YouTubePlaylistSyncDislikedCommand({required this.env}) {
    argParser
      ..addOption(
        'name',
        help: 'Destination playlist title.',
        defaultsTo: 'Disliked videos',
      )
      ..addFlag(
        'apply',
        help: 'Create and update the private playlist.',
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
  String get name => 'sync-disliked';

  @override
  String get description =>
      'Copies disliked videos into a private playlist without duplicates.';

  @override
  Future<int> run() async {
    final envFilePath = argResults!['env-file'] as String;
    final shouldApply = argResults!['apply'] as bool;
    final playlistName = argResults!['name'] as String;
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
      final videos = await client.fetchRatedVideos('dislike');
      stdout.writeln('${videos.length} disliked video(s) found.');
      for (final video in videos) {
        stdout.writeln('- ${video.title} (${video.id})');
      }

      if (!shouldApply) {
        stdout.writeln('Dry run: use --apply to sync "$playlistName".');
        return 0;
      }

      final playlists = await client.fetchOwnedPrivatePlaylistsByTitle();
      final result = await syncPrivatePlaylist(
        client: client,
        playlistsByTitle: playlists,
        title: playlistName,
        description: 'Videos marked as disliked, synchronized by Acervo.',
        videos: videos,
      );
      stdout.writeln(
        '${result.created ? 'Created' : 'Updated'} private playlist '
        '"$playlistName": ${result.added} added, '
        '${result.alreadyPresent} already present.',
      );
      return 0;
    } on YouTubeApiException catch (error) {
      stderr.writeln(error);
      return 70;
    } finally {
      client.close();
    }
  }
}
