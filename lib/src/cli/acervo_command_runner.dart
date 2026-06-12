import 'package:args/command_runner.dart';

import 'package:acervo/src/cli/config/environment.dart';
import 'package:acervo/src/youtube/commands/youtube_command.dart';

/// Builds the root command runner and wires shared application dependencies.
CommandRunner<int> buildCommandRunner({required Environment env}) {
  return CommandRunner<int>(
    'acervo',
    'Organize, review, and rediscover saved content.',
  )..addCommand(YouTubeCommand(env: env));
}
