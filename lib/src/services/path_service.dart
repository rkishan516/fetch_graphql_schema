import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:scoped_zone/scoped_zone.dart';
import 'package:xdg_directories/xdg_directories.dart' as xdg;

/// A reference to a [PathService] instance.
final pathServiceRef = create(PathService.new);

/// The [PathService] instance available in the current zone.
PathService get pathService => read(pathServiceRef);

/// Wraps the path package functionality to allow us to write
/// deterministic unit tests when using path related functionality
class PathService {
  String get separator => p.separator;

  String join(String part1,
          [String? part2,
          String? part3,
          String? part4,
          String? part5,
          String? part6,
          String? part7,
          String? part8]) =>
      p.join(
        part1,
        part2,
        part3,
        part4,
        part5,
        part6,
        part7,
        part8,
      );

  String basename(String path) => p.basename(path);

  /// The a single base directory relative to which user-specific configuration
  /// files should be written. (Corresponds to $XDG_CONFIG_HOME).
  Directory get configHome => xdg.configHome;
}
