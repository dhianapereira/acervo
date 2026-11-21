import 'package:args/command_runner.dart';

import 'package:acervo/src/cli/config/environment.dart';
import 'package:acervo/src/youtube/commands/youtube_playlist_categorize_liked_command.dart';
import 'package:acervo/src/youtube/commands/youtube_playlist_sort_command.dart';
import 'package:acervo/src/youtube/commands/youtube_playlist_sync_disliked_command.dart';

class YouTubePlaylistCommand extends Command<int> {
  YouTubePlaylistCommand({required Environment env}) {
    addSubcommand(YouTubePlaylistSortCommand(env: env));
    addSubcommand(YouTubePlaylistSyncDislikedCommand(env: env));
    addSubcommand(YouTubePlaylistCategorizeLikedCommand(env: env));
  }

  @override
  String get description => 'Commands for YouTube playlists.';

  @override
  String get name => 'playlist';
}
