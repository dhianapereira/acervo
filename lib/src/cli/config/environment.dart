import 'dart:io';

import 'package:dotenv/dotenv.dart';

/// Runtime configuration loaded from the shell environment plus a local `.env`.
///
/// Values exported by the shell win over values from `.env`, and explicit CLI
/// flags should still win over both at the command level.
class Environment {
  const Environment._(this._env);

  final DotEnv _env;

  factory Environment.load({
    String envFilePath = '.env',
    Map<String, String>? platformEnvironment,
  }) {
    final env = DotEnv(quiet: true)..load([envFilePath]);

    env.addAll(platformEnvironment ?? Platform.environment);
    return Environment._(env);
  }

  /// Returns a config value by name, or `null` when it was not configured.
  String? get(String name) => _env[name];
}
