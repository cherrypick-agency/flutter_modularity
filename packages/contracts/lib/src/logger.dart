/// Severity levels for framework log messages.
enum LogLevel {
  /// Verbose diagnostics useful during development.
  debug,

  /// Informational messages about normal operation.
  info,

  /// Conditions that may indicate a problem.
  warning,

  /// Errors that require attention.
  error,
}

/// Contract for logging framework events.
///
/// Implement this interface to route Modularity log output to your
/// preferred logging backend.
abstract class ModularityLogger {
  /// Emit a log entry with the given [message] and optional metadata.
  void log(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  });
}
