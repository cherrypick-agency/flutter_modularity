import 'module.dart';

/// Defines how a `ModuleScope` should manage the lifetime of a module
/// relative to the surrounding UI/navigation events.
enum ModuleRetentionPolicy {
  /// Dispose when the owning route leaves the navigator stack
  /// (default RouteObserver-driven behaviour).
  routeBound,

  /// Keep the module alive across widget unmounts. The controller is cached
  /// and must be released manually or when all interested scopes detach.
  keepAlive,

  /// Always dispose as soon as the corresponding `ModuleScope` leaves the tree.
  strict,
}

/// Context payload used to derive a deterministic retention identity.
class ModuleRetentionContext {
  /// Create a retention context for the given [moduleType].
  ModuleRetentionContext({
    required this.moduleType,
    this.routeName,
    this.routePath,
    this.argumentsHash,
    this.parentKey,
    Map<String, Object?>? extras,
  }) : extras = extras == null ? const {} : Map.unmodifiable(extras);

  /// Runtime type of the module instance.
  final Type moduleType;

  /// Optional router-provided name (e.g. `RouteSettings.name`).
  final String? routeName;

  /// Optional router-specific path (e.g. `/users/:id`).
  final String? routePath;

  /// Precomputed hash of the arguments/config passed to the module.
  final int? argumentsHash;

  /// Identity of the parent scope if available (allows nested modules to
  /// inherit a stable namespace).
  final Object? parentKey;

  /// Additional metadata supplied by adapter layers.
  final Map<String, Object?> extras;
}

/// Optional mixin for modules that know how to compute their own retention key.
mixin RetentionIdentityProvider on Module {
  /// Returns an object that uniquely identifies this module instance for
  /// retention purposes. The value must be stable across rebuilds.
  Object? buildRetentionIdentity(ModuleRetentionContext context);
}
