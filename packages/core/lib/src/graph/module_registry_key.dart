import '../engine/module_override_scope.dart';

/// Key used in the global module registry to differentiate controller
/// instances not only by their runtime type but also by override scope.
class ModuleRegistryKey {
  const ModuleRegistryKey({
    required this.moduleType,
    this.overrideScope,
  });

  final Type moduleType;
  final ModuleOverrideScope? overrideScope;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ModuleRegistryKey &&
        other.moduleType == moduleType &&
        identical(other.overrideScope, overrideScope);
  }

  @override
  int get hashCode => Object.hash(moduleType, overrideScope);
}
