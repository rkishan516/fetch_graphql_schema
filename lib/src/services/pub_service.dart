import 'dart:io';

import 'package:fetch_graphql_schema/src/commands/fetch_graphql_schema_cli_command_runner.dart';
import 'package:fetch_graphql_schema/src/services/process_service.dart';
import 'package:pub_updater/pub_updater.dart';
import 'package:scoped_zone/scoped_zone.dart';

const String currentVersionNotAvailable = 'Current Version Not Available';

/// A reference to a [PubService] instance.
final pubServiceRef = create(PubService.new);

/// The [PubService] instance available in the current zone.
PubService get pubService => read(pubServiceRef);

/// Provides functionality to interact with pacakges
class PubService {
  final _pubUpdater = PubUpdater();

  /// Returns current `fetch_graphql_schema` version installed on the system.
  Future<String> getCurrentVersion() async {
    String version = currentVersionNotAvailable;

    final packages = await processService.runPubGlobalList();
    for (var package in packages) {
      if (!package.contains(executableName)) continue;

      version = package.split(' ').last;
      break;
    }

    return version;
  }

  /// Returns the latest published version of `fetch_graphql_schema` package.
  Future<String> getLatestVersion() async {
    return await _pubUpdater.getLatestVersion(executableName);
  }

  /// Checks whether or not has the latest version for `fetch_graphql_schema` package
  /// installed on the system.
  Future<bool> hasLatestVersion() async {
    final currentVersion = await getCurrentVersion();
    if (currentVersion == currentVersionNotAvailable) {
      await update();
      return true;
    }

    return await _pubUpdater.isUpToDate(
      packageName: executableName,
      currentVersion: currentVersion,
    );
  }

  /// Updates `fetch_graphql_schema` package on the system.
  Future<ProcessResult> update() async {
    return await _pubUpdater.update(packageName: executableName);
  }
}
