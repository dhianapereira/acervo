import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:args/command_runner.dart';

import 'package:acervo/src/cli/config/env_file.dart';
import 'package:acervo/src/cli/config/environment.dart';
import 'package:acervo/src/youtube/data/youtube_oauth_client.dart';

class YouTubeAuthCommand extends Command<int> {
  YouTubeAuthCommand({required this.env}) {
    argParser
      ..addOption(
        'port',
        help: 'Local callback port registered in the OAuth client.',
        defaultsTo: '53682',
      )
      ..addOption(
        'env-file',
        help: 'Dotenv file to update with the generated tokens.',
        defaultsTo: '.env',
      );
  }

  final Environment env;

  @override
  String get description => 'Authorize Acervo with YouTube OAuth.';

  @override
  String get name => 'auth';

  @override
  Future<int> run() async {
    final clientId = env.get('YOUTUBE_CLIENT_ID');
    final clientSecret = env.get('YOUTUBE_CLIENT_SECRET');

    if (clientId == null || clientId.isEmpty) {
      usageException('Configure YOUTUBE_CLIENT_ID in the .env.');
    }

    if (clientSecret == null || clientSecret.isEmpty) {
      usageException('Configure YOUTUBE_CLIENT_SECRET in the .env.');
    }

    final port = int.parse(argResults!['port'] as String);
    final envFilePath = argResults!['env-file'] as String;
    final redirectUri = 'http://localhost:$port/oauth2callback';
    final state = _randomState();
    HttpServer? server;
    YouTubeOAuthClient? oauthClient;

    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      oauthClient = YouTubeOAuthClient();
      final authorizationUrl = oauthClient.buildAuthorizationUrl(
        clientId: clientId,
        redirectUri: redirectUri,
        state: state,
      );

      stdout.writeln('Open this URL and authorize Acervo:');
      stdout.writeln(authorizationUrl);
      stdout.writeln('');
      stdout.writeln('Waiting for Google to redirect back to $redirectUri ...');

      final request = await server.first.timeout(const Duration(minutes: 5));
      final query = request.uri.queryParameters;
      final error = query['error'];
      final code = query['code'];

      if (request.uri.path != '/oauth2callback') {
        await _sendHtml(request.response, 'Invalid callback path.');
        stderr.writeln('Invalid OAuth callback path: ${request.uri.path}');
        return 64;
      }

      if (query['state'] != state) {
        await _sendHtml(request.response, 'Invalid OAuth state.');
        stderr.writeln('Invalid OAuth state.');
        return 70;
      }

      if (error != null) {
        await _sendHtml(request.response, 'Authorization failed.');
        stderr.writeln('Google rejected the authorization: $error');
        return 70;
      }

      if (code == null || code.isEmpty) {
        await _sendHtml(request.response, 'Missing authorization code.');
        stderr.writeln('Google did not return an authorization code.');
        return 70;
      }

      final token = await oauthClient.exchangeAuthorizationCode(
        clientId: clientId,
        clientSecret: clientSecret,
        redirectUri: redirectUri,
        code: code,
      );

      final values = {'YOUTUBE_ACCESS_TOKEN': token.accessToken};
      final refreshToken = token.refreshToken;
      if (refreshToken != null && refreshToken.isNotEmpty) {
        values['YOUTUBE_REFRESH_TOKEN'] = refreshToken;
      }

      EnvFile(envFilePath).upsertAll(values);
      await _sendHtml(
        request.response,
        'Acervo is authorized. You can close this tab.',
      );
      stdout.writeln('Updated $envFilePath with YouTube OAuth tokens.');
      return 0;
    } on TimeoutException {
      stderr.writeln('Timed out waiting for OAuth callback.');
      return 70;
    } on YouTubeOAuthException catch (error) {
      stderr.writeln(error);
      return 70;
    } finally {
      await server?.close(force: true);
      oauthClient?.close();
    }
  }

  String _randomState() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  Future<void> _sendHtml(HttpResponse response, String message) async {
    response.headers.contentType = ContentType.html;
    response.write(
      '<!doctype html><title>Acervo</title>'
      '<body style="font-family: system-ui, sans-serif;">'
      '<h1>$message</h1>'
      '</body>',
    );
    await response.close();
  }
}
