import 'dart:async';

import 'package:args/args.dart';
import 'package:cli_completion/cli_completion.dart';
import 'package:fetch_graphql_schema/src/commands/fetch/fetch_command.dart';
import 'package:fetch_graphql_schema/src/commands/upgrade/upgrade_command.dart';
import 'package:fetch_graphql_schema/src/services/logger.dart';
import 'package:fetch_graphql_schema/src/services/pub_service.dart';
import 'package:mason_logger/mason_logger.dart';

const executableName = 'fetch_graphql_schema';
const packageName = 'fetch_graphql_schema';
const description =
    'Fetch and print the GraphQL schema from a GraphQL HTTP endpoint. (Can be used for Relay Modern.)';

class FetchGraphQLSchemaCliCommandRunner extends CompletionCommandRunner<int> {
  FetchGraphQLSchemaCliCommandRunner() : super(executableName, description) {
    argParser.addFlag(
      'version',
      negatable: false,
      help: 'Print the current version.',
    );
    argParser.addFlag(
      'verbose',
      abbr: 'v',
      help: 'Noisy logging, including all shell commands executed.',
      callback: (verbose) {
        if (verbose) {
          logger.level = Level.verbose;
        }
      },
    );
    addCommand(FetchCommand());
    addCommand(UpgradeCommand());
  }

  @override
  void printUsage() => logger.info(usage);

  @override
  Future<int> run(Iterable<String> args) async {
    try {
      final argResults = parse(args);

      if (argResults['version']) {
        logger.info(await pubService.getCurrentVersion());
        return ExitCode.success.code;
      }

      await _notifyNewVersionAvailable(arguments: args.toList());
      return await runCommand(argResults) ?? ExitCode.success.code;
    } catch (e) {
      logger.err(e.toString());
      return ExitCode.config.code;
    }
  }

  /// Notifies new version of Fetch GraphQL Schema CLI is available
  Future<void> _notifyNewVersionAvailable({
    List<String> arguments = const [],
    List<String> ignored = const ['upgrade'],
  }) async {
    if (arguments.isEmpty) return;

    for (var arg in ignored) {
      if (arguments.first == arg) return;
    }

    if (await pubService.hasLatestVersion()) return;

    logger.warn('''A new version of Fetch GraphQL Schema is available!''');
  }

  @override
  Future<int?> runCommand(ArgResults topLevelResults) async {
    // Fast track completion command
    if (topLevelResults.command?.name == 'completion') {
      await super.runCommand(topLevelResults);
      return ExitCode.success.code;
    }

    // Run the command or show version
    final int? exitCode;
    if (topLevelResults['version'] == true) {
      exitCode = ExitCode.success.code;
    } else {
      exitCode = await super.runCommand(topLevelResults);
    }

    return exitCode;
  }
}
