import 'binder.dart';

/// Factory for creating [Binder] instances.
///
/// Swap the DI container implementation (e.g. `GetItBinder`, `SimpleBinder`)
/// by providing a different factory to the engine.
abstract class BinderFactory {
  /// Create a new [Binder], optionally linked to a [parent] scope.
  Binder create([Binder? parent]);
}
