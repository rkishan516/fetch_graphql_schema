import 'dart:convert';
import 'dart:io';

import 'package:fetch_graphql_schema/src/commands/fetch/schema_from_json.dart';
import 'package:fetch_graphql_schema/src/commands/fetch_graphql_schema_command.dart';
import 'package:fetch_graphql_schema/src/services/file_service.dart';
import 'package:fetch_graphql_schema/src/services/logger.dart';
import 'package:fetch_graphql_schema/src/services/pubspec_service.dart';
import 'package:http/http.dart';
import 'package:leto_schema/leto_schema.dart';
import 'package:leto_schema/utilities.dart';
import 'package:mason_logger/mason_logger.dart';

/// A command to fetch print and save schema for GraphQL
class FetchCommand extends FetchGraphQLSchemaCommand {
  @override
  String get description =>
      'Fetch and print the GraphQL schema from a GraphQL HTTP endpoint.';

  @override
  String get name => 'fetch';

  FetchCommand() {
    argParser
      ..addFlag(
        'json',
        defaultsTo: false,
        help: 'Output in JSON format (based on introspection query)',
      )
      ..addOption(
        'url',
        help: 'GraphQL HTTP endpoint to fetch schema',
        mandatory: true,
      )
      ..addOption(
        'method',
        help: 'Use Method (GET,POST, PUT, DELETE)',
        allowed: ['GET', 'POST', 'PUT', 'DELETE'],
        defaultsTo: 'POST',
      )
      ..addOption(
        'output',
        help: 'Output file to save',
      )
      ..addMultiOption(
        'header',
        help:
            '''Add a custom header (ex. 'Authorization=Bearer ABC','Version=2.1.0')''',
      );
  }

  @override
  Future<int> run() async {
    try {
      final workingDirectory =
          argResults!.rest.length > 1 ? argResults!.rest[1] : null;
      final jsonRequired = argResults!['json'] as bool;
      final endpoint = argResults!['url'] as String;
      final method = argResults!['method'] as String;
      final output = argResults!['output'] as String?;
      const defaultHeaders = {
        'Content-Type': 'application/json',
      };
      final headers =
          (argResults!['header'] as List<String>).asMap().map((k, e) {
        final pair = e.split('=');
        return MapEntry(pair.first, pair.last);
      });
      await pubspecService.initialise(workingDirectory: workingDirectory);
      final result = await getRemoteSchema(
        defaultHeaders: defaultHeaders,
        headers: headers,
        endPoint: endpoint,
        jsonRequired: jsonRequired,
        method: method,
      );
      if (result.status == Status.err) {
        logger.warn(result.message);
        return ExitCode.ioError.code;
      }
      final printableSchema = printSchema(result.schema!);
      if (output != null) {
        await fileService.writeStringFile(
          file: File(output),
          fileContent: printableSchema,
        );
      } else {
        logger.info(printableSchema);
      }
    } on ArgumentError catch (e) {
      logger.err(e.message.toString());
      return ExitCode.usage.code;
    } catch (e) {
      logger.err(e.toString());
      return ExitCode.usage.code;
    }
    return ExitCode.success.code;
  }

  Future<({Status status, GraphQLSchema? schema, String? message})>
      getRemoteSchema({
    required bool jsonRequired,
    required String endPoint,
    required String method,
    required Map<String, String> headers,
    required Map<String, String> defaultHeaders,
  }) async {
    try {
      final res = await Client().send(
        Request(
          argResults!['method'] as String,
          Uri.parse(endPoint),
        )
          ..headers.addAll({
            ...defaultHeaders,
            ...headers,
          })
          ..body = json.encode({'query': getIntrospectionQuery()}),
      );
      if (res.statusCode != 200) {
        return (
          status: Status.err,
          schema: null,
          message: 'Faild with status code ${res.statusCode}}'
        );
      }
      final response = await Response.fromStream(res);
      final schema = buildClientSchema(jsonDecode(response.body)["data"]);
      return (status: Status.ok, schema: schema, message: null);
    } catch (e) {
      return (status: Status.err, schema: null, message: e.toString());
    }
  }
}

enum Status { ok, err }
