import 'package:abstract_http_client/abstract_http_client.dart';

/// Factory function type for creating HTTP clients.
typedef HttpClientFactory = HttpClient Function();

/// Configuration for a single named HTTP client.
class NamedHttpClientConfig {
  const NamedHttpClientConfig({
    required this.name,
    required this.clientFactory,
    this.isDefault = false,
  });

  /// Unique name for this client (e.g., 'api', 'auth', 'cdn').
  final String name;

  /// Factory function that creates the HTTP client instance.
  ///
  /// The factory should return a fully configured [HttpClient] instance.
  /// The module will call [HttpClient.initialize] after creation.
  ///
  /// Example:
  /// ```dart
  /// NamedHttpClientConfig(
  ///   name: 'api',
  ///   clientFactory: () => DioHttpClient(
  ///     config: DioHttpClientConfig(
  ///       baseUrl: Uri.parse('https://api.example.com'),
  ///     ),
  ///   ),
  /// )
  /// ```
  final HttpClientFactory clientFactory;

  /// Whether this client should be the default client.
  ///
  /// Only one client can be marked as default.
  /// If no client is marked as default, the first one will be used.
  final bool isDefault;
}

/// Configuration for [HttpClientModule].
///
/// Example:
/// ```dart
/// HttpClientModuleConfig(
///   clients: [
///     NamedHttpClientConfig(
///       name: 'api',
///       clientFactory: () => DioHttpClient(
///         config: DioHttpClientConfig(
///           baseUrl: Uri.parse('https://api.example.com'),
///         ),
///       ),
///       isDefault: true,
///     ),
///     NamedHttpClientConfig(
///       name: 'cdn',
///       clientFactory: () => DioHttpClient(
///         config: DioHttpClientConfig(
///           baseUrl: Uri.parse('https://cdn.example.com'),
///         ),
///       ),
///     ),
///   ],
/// )
/// ```
class HttpClientModuleConfig {
  const HttpClientModuleConfig({required this.clients});

  /// List of named client configurations.
  ///
  /// At least one client is required.
  final List<NamedHttpClientConfig> clients;

  /// Validates the configuration.
  ///
  /// Throws [ArgumentError] if:
  /// - No clients are configured
  /// - Multiple clients are marked as default
  /// - Client names are not unique
  void validate() {
    if (clients.isEmpty) {
      throw ArgumentError('At least one client configuration is required');
    }

    final defaults = clients.where((c) => c.isDefault).toList();
    if (defaults.length > 1) {
      final names = defaults.map((c) => c.name).join(', ');
      throw ArgumentError(
        'Only one client can be marked as default. Found: [$names]',
      );
    }

    final names = clients.map((c) => c.name).toSet();
    if (names.length != clients.length) {
      throw ArgumentError('Client names must be unique');
    }
  }

  /// Gets the default client configuration.
  ///
  /// Returns the client marked as default, or the first client if none is marked.
  NamedHttpClientConfig get defaultClient {
    return clients.firstWhere((c) => c.isDefault, orElse: () => clients.first);
  }
}
