// ignore_for_file: constant_identifier_names, unnecessary_string_escapes

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:fetch_graphql_schema/src/services/logger.dart';
import 'package:scoped_zone/scoped_zone.dart';

/// A reference to a [FileService] instance.
final fileServiceRef = create(FileService.new);

/// The [FileService] instance available in the current zone.
FileService get fileService => read(fileServiceRef);

/// Handles the writing of files to disk
class FileService {
  Future<void> writeStringFile({
    required File file,
    required String fileContent,
    bool verbose = false,
    FileModificationType type = FileModificationType.Create,
    String? verboseMessage,
    bool forceAppend = false,
  }) async {
    if (!(await file.exists())) {
      if (type != FileModificationType.Create) {
        logger.warn('File does not exist. Write it out');
      }
      await file.create(recursive: true);
    }

    await file.writeAsString(
      fileContent,
      mode: forceAppend ? FileMode.append : FileMode.write,
    );

    if (verbose) {
      logger.detail(verboseMessage ?? '$file operated with ${type.name}');
    }
  }

  Future<void> writeDataFile({
    required File file,
    required Uint8List fileContent,
    bool verbose = false,
    FileModificationType type = FileModificationType.Create,
    String? verboseMessage,
    bool forceAppend = false,
  }) async {
    if (!(await file.exists())) {
      if (type != FileModificationType.Create) {
        logger.warn('File does not exist. Write it out');
      }
      await file.create(recursive: true);
    }

    await file.writeAsBytes(
      fileContent,
      mode: forceAppend ? FileMode.append : FileMode.write,
    );

    if (verbose) {
      logger.detail(verboseMessage ?? '$file operated with $type');
    }
  }

  /// Delete a file at the given path
  ///
  /// Args:
  ///   filePath (String): The path to the file you want to delete.
  ///   verbose (bool): Determine if should log the action or not.
  Future<void> deleteFile({
    required String filePath,
    bool verbose = true,
  }) async {
    final file = File(filePath);
    await file.delete();
    if (verbose) {
      logger.detail('$file deleted');
    }
  }

  /// Check if the file at [filePath] exists
  Future<bool> fileExists({required String filePath}) {
    return File(filePath).exists();
  }
}

// enum for file modification types
enum FileModificationType {
  Append,
  Create,
  Modify,
  Delete,
}
