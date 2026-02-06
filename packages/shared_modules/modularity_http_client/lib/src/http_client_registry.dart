import 'package:abstract_http_client/abstract_http_client.dart';
import 'package:modularity_contracts/modularity_contracts.dart';

/// Registry for named HTTP clients.
///
/// Since [Binder] doesn't support qualifiers, this registry provides
/// access to multiple HTTP clients by name.
///
/// Example:
/// ```dart
/// final api = registry.get('api');
/// final cdn = registry.get('cdn');
/// ```
class HttpClientRegistry {
  final Map<String, HttpClient> _clients = {};
  String? _defaultName;

  /// Registers a client with the given name.
  ///
  /// Throws [StateError] if a client with this name is already registered.
  void register(String name, HttpClient client, {bool isDefault = false}) {
    if (_clients.containsKey(name)) {
      throw ModuleConfigurationException(
        'HttpClient with name "$name" is already registered.',
      );
    }
    _clients[name] = client;
    if (isDefault || _defaultName == null) {
      _defaultName = name;
    }
  }

  /// Gets a client by name.
  ///
  /// Throws [StateError] if no client with this name is registered.
  HttpClient get(String name) {
    final client = _clients[name];
    if (client == null) {
      throw DependencyNotFoundException(
        'HttpClient "$name" not found.',
        requestedType: HttpClient,
        lookupContext: 'HttpClientRegistry',
      );
    }
    return client;
  }

  /// Gets a client by name or null if not found.
  HttpClient? tryGet(String name) => _clients[name];

  /// Gets the default client.
  ///
  /// Throws [StateError] if no clients are registered.
  HttpClient get defaultClient {
    if (_defaultName == null) {
      throw ModuleConfigurationException('No default HttpClient registered.');
    }
    return _clients[_defaultName]!;
  }

  /// The name of the default client.
  String? get defaultName => _defaultName;

  /// List of all registered client names.
  Iterable<String> get names => _clients.keys;

  /// Number of registered clients.
  int get length => _clients.length;

  /// Whether the registry is empty.
  bool get isEmpty => _clients.isEmpty;

  /// Whether the registry has clients.
  bool get isNotEmpty => _clients.isNotEmpty;

  /// Disposes all registered clients.
  ///
  /// After calling this method, the registry will be empty.
  Future<void> disposeAll() async {
    final futures = <Future<void>>[];
    for (final client in _clients.values) {
      futures.add(client.dispose());
    }
    await Future.wait(futures);
    _clients.clear();
    _defaultName = null;
  }
}
