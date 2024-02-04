import 'dart:convert';
import 'dart:io';

import 'package:fetch_graphql_schema/src/services/logger.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:scoped_zone/scoped_zone.dart';

/// A reference to a [ProcessService] instance.
final processServiceRef = create(ProcessService.new);

/// The [ProcessService] instance available in the current zone.
ProcessService get processService => read(processServiceRef);

/// helper service to run flutter commands
class ProcessService {
  /// It runs the `dart pub global activate` command in the app's directory
  Future<void> runPubGlobalActivate() async {
    await _runProcess(
      programName: 'dart',
      arguments: ['pub', 'global', 'activate'],
    );
  }

  /// Runs the `dart pub global list` command and returns a list of strings
  /// representing packages with their version.
  Future<List<String>> runPubGlobalList() async {
    final output = <String>[];
    await _runProcess(
      programName: 'dart',
      arguments: ['pub', 'global', 'list'],
      verbose: false,
      handleOutput: (lines) async => output.addAll(lines),
    );

    return output;
  }

  /// It runs a process and logs the output to the console when [verbose] is true.
  ///
  /// Args:
  ///   programName (String): The name of the program to run.
  ///   arguments (List<String>): The arguments to pass to the program. Defaults to const []
  ///   workingDirectory (String): The directory to run the command in.
  ///   verbose (bool): Determine when to log the output to the console.
  ///   handleOutput (Function): Function passed to handle the output.
  Future<void> _runProcess({
    required String programName,
    List<String> arguments = const [],
    String? workingDirectory,
    bool verbose = true,
    Future<void> Function(List<String> lines)? handleOutput,
  }) async {
    Progress? progress;
    if (verbose) {
      final hasWorkingDirectory = workingDirectory != null;
      progress = logger.progress(
          'Running $programName ${arguments.join(' ')} ${hasWorkingDirectory ? 'in $workingDirectory/' : ''}...');
    }

    try {
      final process = await Process.start(
        programName,
        arguments,
        workingDirectory: workingDirectory,
        runInShell: true,
      );

      final lines = <String>[];
      final lineSplitter = LineSplitter();
      await process.stdout.transform(utf8.decoder).forEach((output) {
        if (verbose) logger.detail(output);

        if (handleOutput != null) {
          lines.addAll(lineSplitter
              .convert(output)
              .map((l) => l.trim())
              .where((l) => l.isNotEmpty)
              .toList());
        }
      });

      await handleOutput?.call(lines);

      final exitCode = await process.exitCode;

      if (verbose) {
        if (exitCode == 0) {
          progress!.complete(
              'Successfully ran $programName ${arguments.join(' ')} ${workingDirectory != null ? 'in $workingDirectory/' : ''}.');
        } else {
          progress!.fail(
              'Failed to run $programName ${arguments.join(' ')} ${workingDirectory != null ? 'in $workingDirectory/' : ''}. ExitCode: $exitCode');
        }
      }
    } on ProcessException catch (e) {
      final message =
          'Command failed. Command executed: $programName ${arguments.join(' ')}\nException: ${e.message}';
      if (verbose) {
        progress!.fail(message);
      } else {
        logger.err(message);
      }
    } catch (e) {
      final message =
          'Command failed. Command executed: $programName ${arguments.join(' ')}\nException: ${e.toString()}';
      if (verbose) {
        progress!.fail(message);
      } else {
        logger.err(message);
      }
    }
  }
}
