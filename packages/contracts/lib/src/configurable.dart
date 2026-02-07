/// Interface for modules that require configuration before initialization.
/// Used to pass arguments (e.g. a route id) into a module.
abstract class Configurable<T> {
  /// Called by the framework before [Module.binds] and [Module.onInit].
  void configure(T args);
}
