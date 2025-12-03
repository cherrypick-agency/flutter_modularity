import 'package:modularity_contracts/modularity_contracts.dart';

typedef BinderOverride = void Function(Binder binder);

BinderOverride? _composeOverrides(
    BinderOverride? first, BinderOverride? second) {
  if (first == null) return second;
  if (second == null) return first;
  return (binder) {
    first(binder);
    second(binder);
  };
}

/// Дерево overrides для текущего модуля и его дочерних импортов.
class ModuleOverrideScope {
  final BinderOverride? selfOverrides;
  final Map<Type, ModuleOverrideScope> children;

  const ModuleOverrideScope({
    this.selfOverrides,
    this.children = const {},
  });

  /// Возвращает скоуп для импортируемого модуля типа [type].
  ModuleOverrideScope? childFor(Type type) => children[type];

  /// Создает новый scope с объединёнными overrides (сначала выполняется текущий,
  /// затем [override]).
  ModuleOverrideScope withAdditionalOverride(BinderOverride? override) {
    return ModuleOverrideScope(
      selfOverrides: _composeOverrides(selfOverrides, override),
      children: children,
    );
  }

  /// Слияние двух scope-ов. Overrides выполняются в порядке: текущий -> [other].
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
