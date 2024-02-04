import 'dart:io';

import 'package:pubspec_yaml/pubspec_yaml.dart';
import 'package:scoped_zone/scoped_zone.dart';

/// A reference to a [PubspecService] instance.
final pubspecServiceRef = create(PubspecService.new);

/// The [PubspecService] instance available in the current zone.
PubspecService get pubspecService => read(pubspecServiceRef);

/// Provides functionality to interact with the pubspec in the current project
class PubspecService {
  late PubspecYaml pubspecYaml;

  /// Reads the pubpec and caches the value locally
  Future<void> initialise({String? workingDirectory}) async {
    final bool hasWorkingDirectory = workingDirectory != null;
    // stdout.writeln('PubspecService - initialise from pubspec.yaml');
    final pubspecYamlContent = await File(
            '${hasWorkingDirectory ? '$workingDirectory/' : ''}pubspec.yaml')
        .readAsString();
    pubspecYaml = pubspecYamlContent.toPubspecYaml();
    // stdout.writeln('PubspecService - initialise complete');
  }

  String get getPackageName => pubspecYaml.name;
}
