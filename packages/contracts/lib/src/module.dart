import 'dart:async';
import 'binder.dart';
import 'configurable.dart';

/// Lifecycle statuses of a module.
enum ModuleStatus {
  /// Module has just been created, nothing has happened yet.
  initial,

  /// Module is currently initializing (onInit is running).
  loading,

  /// Module has been successfully initialized and is ready to use.
  loaded,

  /// An error occurred during initialization.
  error,

  /// Module has been disposed.
  disposed,
}

/// Base contract for a Module.
/// A module is a unit of logic with its own lifecycle and dependencies.
abstract class Module {
  /// List of modules this module depends on.
  /// They will be initialized BEFORE this module starts.
  List<Module> get imports => [];

  /// List of structural sub-features that compose this module.
  /// Used for static analysis and visualization ONLY.
  /// Modules listed here should use the [Configurable] interface for runtime parameters
  /// instead of constructor arguments, allowing for clean static instantiation.
  List<Module> get submodules => [];

  /// List of types that the parent scope MUST provide.
  /// Checked at startup. If a type is missing, initialization fails with an error.
  List<Type> get expects => [];

  /// Registers dependencies available ONLY within this module (Private).
  /// Declare repository implementations, data sources, mappers, and other
  /// internal details here. These dependencies do not leave the module boundary
  /// and are not visible to importers.
  void binds(Binder i);

  /// Registers dependencies that this module exposes to the outside world (Public).
  /// These dependencies will be available to modules that import this one.
  /// Only public interfaces/facades should be exported here,
  /// relying on previously registered private dependencies.
  void exports(Binder i) {}

  /// Asynchronous initialization.
  /// Called after all [imports] have reached [ModuleStatus.loaded] status,
  /// and after [binds] and [exports] have been executed.
  Future<void> onInit() async {}

  /// Resource cleanup.
  /// Called when the module is being disposed.
  void onDispose() {}

  /// Hook for Hot Reload.
  /// Allows updating factories without losing singleton state.
  void hotReload(Binder i) {}
}
