import 'dart:io';

import 'package:fetch_graphql_schema/src/commands/fetch_graphql_schema_cli_command_runner.dart';
import 'package:fetch_graphql_schema/src/services/file_service.dart';
import 'package:fetch_graphql_schema/src/services/logger.dart';
import 'package:fetch_graphql_schema/src/services/path_service.dart';
import 'package:fetch_graphql_schema/src/services/process_service.dart';
import 'package:fetch_graphql_schema/src/services/pub_service.dart';
import 'package:fetch_graphql_schema/src/services/pubspec_service.dart';
import 'package:scoped_zone/scoped_zone.dart';

Future<void> main(List<String> args) async {
  await _flushThenExit(
    await runScoped(
      () async => FetchGraphQLSchemaCliCommandRunner().run(args),
      values: {
        fileServiceRef,
        loggerRef,
        pathServiceRef,
        processServiceRef,
        pubServiceRef,
        pubspecServiceRef,
      },
    ),
  );
}

/// Flushes the stdout and stderr streams, then exits the program with the given
/// status code.
///
/// This returns a Future that will never complete, since the program will have
/// exited already. This is useful to prevent Future chains from proceeding
/// after you've decided to exit.
Future<void> _flushThenExit(int status) {
  return Future.wait<void>([stdout.close(), stderr.close()])
      .then<void>((_) => exit(status));
}
