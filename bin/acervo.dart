import 'dart:io';

import 'package:acervo/acervo.dart';
import 'package:args/command_runner.dart';

Future<void> main(List<String> arguments) async {
  final env = Environment.load();
  final runner = buildCommandRunner(env: env);

  try {
    final exitCode = await runner.run(arguments) ?? 0;
    exit(exitCode);
  } on UsageException catch (error) {
    stderr.writeln(error);
    exit(64);
  }
}
