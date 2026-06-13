import 'package:args/command_runner.dart';

import 'package:acervo/src/cli/config/environment.dart';
import 'package:acervo/src/youtube/commands/youtube_auth_command.dart';
import 'package:acervo/src/youtube/commands/youtube_playlist_command.dart';

class YouTubeCommand extends Command<int> {
  YouTubeCommand({required Environment env}) {
    addSubcommand(YouTubeAuthCommand(env: env));
    addSubcommand(YouTubePlaylistCommand(env: env));
  }

  @override
  String get description => 'Commands for organizing YouTube content.';

  @override
  String get name => 'youtube';
}
