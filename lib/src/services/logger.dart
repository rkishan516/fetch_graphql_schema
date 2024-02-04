import 'package:mason_logger/mason_logger.dart';
import 'package:scoped_zone/scoped_zone.dart';

/// A reference to a [Logger] instance.
final loggerRef = create(Logger.new);

/// The [Logger] instance available in the current zone.
Logger get logger => read(loggerRef);
