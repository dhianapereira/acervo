import 'dart:io';

import 'package:args/command_runner.dart';

import 'package:acervo/src/cli/config/env_file.dart';
import 'package:acervo/src/cli/config/environment.dart';
import 'package:acervo/src/youtube/data/youtube_api_client.dart';
import 'package:acervo/src/youtube/data/youtube_oauth_client.dart';
import 'package:acervo/src/youtube/domain/playlist_sorter.dart';

class YouTubePlaylistSortCommand extends Command<int> {
  YouTubePlaylistSortCommand({required this.env}) {
    argParser
      ..addOption(
        'playlist',
        abbr: 'p',
        help: 'YouTube playlist URL or ID.',
        mandatory: true,
      )
      ..addFlag(
        'apply',
        help: 'Apply the new playlist order. Without this, prints a dry run.',
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
  String get description =>
      'Sorts a playlist by the videos original publication date.';

  @override
  String get name => 'sort';

  @override
  Future<int> run() async {
    final playlistInput = argResults!['playlist'] as String;
    final shouldApply = argResults!['apply'] as bool;
    final envFilePath = argResults!['env-file'] as String;
    final String? accessToken;
    try {
      accessToken = await _resolveAccessToken(envFilePath);
    } on YouTubeOAuthException catch (error) {
      stderr.writeln(
        'Could not refresh YouTube authorization: ${error.message}',
      );
      stderr.writeln(
        'Run "dart run acervo youtube auth --env-file $envFilePath" '
        'to authorize again.',
      );
      return 70;
    }

    if (accessToken == null || accessToken.isEmpty) {
      usageException(
        'Configure YOUTUBE_ACCESS_TOKEN in the .env or run '
        '"acervo youtube auth".',
      );
    }

    final playlistId = extractYouTubePlaylistId(playlistInput);
    final client = YouTubeApiClient(accessToken: accessToken);

    try {
      final items = await client.fetchPlaylistItems(playlistId);
      final sorted = sortByVideoPublicationDate(items);

      stdout.writeln(
        shouldApply
            ? 'Applying new order to ${sorted.length} videos...'
            : 'Dry run: new order for ${sorted.length} videos:',
      );

      for (var index = 0; index < sorted.length; index += 1) {
        final item = sorted[index];
        stdout.writeln(
          '${index + 1}. ${item.videoPublishedAt.toIso8601String()} '
          '- ${item.title}',
        );

        if (shouldApply && item.position != index) {
          await client.updatePlaylistItemPosition(item: item, position: index);
        }
      }

      if (!shouldApply) {
        stdout.writeln('');
        stdout.writeln('Use --apply to update the playlist on YouTube.');
      }

      return 0;
    } on FormatException catch (error) {
      stderr.writeln(error.message);
      return 64;
    } on YouTubeApiException catch (error) {
      stderr.writeln(error);
      return 70;
    } finally {
      client.close();
    }
  }

  Future<String?> _resolveAccessToken(String envFilePath) async {
    final refreshToken = env.get('YOUTUBE_REFRESH_TOKEN');
    final clientId = env.get('YOUTUBE_CLIENT_ID');
    final clientSecret = env.get('YOUTUBE_CLIENT_SECRET');

    if (refreshToken == null ||
        refreshToken.isEmpty ||
        clientId == null ||
        clientId.isEmpty ||
        clientSecret == null ||
        clientSecret.isEmpty) {
      return env.get('YOUTUBE_ACCESS_TOKEN');
    }

    final oauthClient = YouTubeOAuthClient();
    try {
      final token = await oauthClient.refreshAccessToken(
        clientId: clientId,
        clientSecret: clientSecret,
        refreshToken: refreshToken,
      );
      EnvFile(
        envFilePath,
      ).upsertAll({'YOUTUBE_ACCESS_TOKEN': token.accessToken});
      return token.accessToken;
    } finally {
      oauthClient.close();
    }
  }
}
