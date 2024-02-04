import 'dart:async';

import 'package:fetch_graphql_schema/src/commands/fetch_graphql_schema_command.dart';
import 'package:fetch_graphql_schema/src/services/logger.dart';
import 'package:fetch_graphql_schema/src/services/process_service.dart';
import 'package:fetch_graphql_schema/src/services/pub_service.dart';
import 'package:mason_logger/mason_logger.dart';

/// A command that updates the Fetch GraphQL Schema CLI tool to the latest version.
class UpgradeCommand extends FetchGraphQLSchemaCommand {
  @override
  String get description =>
      '''Updates Fetch GraphQL Schema CLI to latest version.''';

  @override
  String get name => 'upgrade';

  @override
  Future<int> run() async {
    try {
      if (await pubService.hasLatestVersion()) {
        logger.info('Fetch GraphQL Schema CLI is already up to date.');
        return ExitCode.success.code;
      }

      final progress = logger.progress('Updating Fetch GraphQL Schema CLI');
      await processService.runPubGlobalActivate();
      progress.complete('Successfully updated Fetch GraphQL Schema CLI');
      return ExitCode.success.code;
    } catch (e) {
      logger.err(e.toString());
      return ExitCode.usage.code;
    }
  }
}
