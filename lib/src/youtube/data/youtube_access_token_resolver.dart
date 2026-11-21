import 'package:acervo/src/cli/config/env_file.dart';
import 'package:acervo/src/cli/config/environment.dart';
import 'package:acervo/src/youtube/data/youtube_oauth_client.dart';

Future<String?> resolveYouTubeAccessToken({
  required Environment env,
  required String envFilePath,
}) async {
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
    EnvFile(envFilePath).upsertAll({'YOUTUBE_ACCESS_TOKEN': token.accessToken});
    return token.accessToken;
  } finally {
    oauthClient.close();
  }
}
