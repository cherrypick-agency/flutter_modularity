import 'package:modularity_contracts/modularity_contracts.dart';

/// Callback that applies dependency overrides to the given [Binder].
typedef BinderOverride = void Function(Binder binder);

BinderOverride? _composeOverrides(
  BinderOverride? first,
  BinderOverride? second,
) {
  if (first == null) return second;
  if (second == null) return first;
  return (binder) {
    first(binder);
    second(binder);
  };
}

/// Hierarchical tree of [BinderOverride]s for the current module and its
/// imported children.
class ModuleOverrideScope {
  /// Create a scope with optional [selfOverrides] and child [children] map.
  const ModuleOverrideScope({this.selfOverrides, this.children = const {}});

  /// Override callback applied to the owning module's [Binder], or `null` if
  /// no overrides are needed at this level.
  final BinderOverride? selfOverrides;

  /// Per-module-type override scopes for imported (child) modules.
  final Map<Type, ModuleOverrideScope> children;

  /// Returns the override scope for the imported module of the given [type].
  ModuleOverrideScope? childFor(Type type) => children[type];

  /// Creates a new scope with combined overrides (current first, then [override]).
  ModuleOverrideScope withAdditionalOverride(BinderOverride? override) {
    return ModuleOverrideScope(
      selfOverrides: _composeOverrides(selfOverrides, override),
      children: children,
    );
  }

  /// Merges two scopes. Overrides are applied in order: current -> [other].
  ModuleOverrideScope merge(ModuleOverrideScope? other) {
    if (other == null) return this;
    final mergedChildren = <Type, ModuleOverrideScope>{}..addAll(children);
    other.children.forEach((key, value) {
      final existing = mergedChildren[key];
      mergedChildren[key] = existing == null ? value : existing.merge(value);
    });

    return ModuleOverrideScope(
      selfOverrides: _composeOverrides(selfOverrides, other.selfOverrides),
      children: mergedChildren,
    );
  }
}
