import 'package:args/command_runner.dart';

import 'package:acervo/src/cli/config/environment.dart';
import 'package:acervo/src/youtube/commands/youtube_playlist_sort_command.dart';

class YouTubePlaylistCommand extends Command<int> {
  YouTubePlaylistCommand({required Environment env}) {
    addSubcommand(YouTubePlaylistSortCommand(env: env));
  }

  @override
  String get description => 'Commands for YouTube playlists.';

  @override
  String get name => 'playlist';
}
