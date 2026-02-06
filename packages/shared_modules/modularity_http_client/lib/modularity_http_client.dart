/// HTTP Client module for Modularity framework with named clients support.
///
/// This library provides a [HttpClientModule] that manages HTTP clients
/// with support for multiple named clients.
///
/// ## Getting Started
///
/// ```dart
/// import 'package:modularity_http_client/modularity_http_client.dart';
/// import 'package:dio_http_client/dio_http_client.dart';
///
/// // Configure the module
/// ModuleScope(
///   module: HttpClientModule(),
///   args: HttpClientModuleConfig(
///     clients: [
///       NamedHttpClientConfig(
///         name: 'api',
///         clientFactory: () => DioHttpClient(
///           config: DioHttpClientConfig(
///             baseUrl: Uri.parse('https://api.example.com'),
///           ),
///         ),
///         isDefault: true,
///       ),
///     ],
///   ),
///   child: MyApp(),
/// )
/// ```
///
/// ## Accessing Clients
///
/// ```dart
/// // Get the default client
/// final client = binder.get<HttpClient>();
///
/// // Get a specific client by name
/// final registry = binder.get<HttpClientRegistry>();
/// final api = registry.get('api');
/// final cdn = registry.get('cdn');
/// ```
library modularity_http_client;

export 'src/http_client_module.dart';
export 'src/http_client_module_config.dart';
export 'src/http_client_registry.dart';
