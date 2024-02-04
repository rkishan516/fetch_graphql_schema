import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:fetch_graphql_schema/src/commands/fetch_graphql_schema_cli_command_runner.dart';

abstract class FetchGraphQLSchemaCommand extends Command<int> {
  @override
  FetchGraphQLSchemaCliCommandRunner? get runner =>
      super.runner as FetchGraphQLSchemaCliCommandRunner?;

  /// [ArgResults] used for testing purposes only.
  ArgResults? testArgResults;

  /// [ArgResults] for the current command.
  ArgResults get results => testArgResults ?? argResults!;
}
