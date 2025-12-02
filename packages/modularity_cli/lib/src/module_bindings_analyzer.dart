import 'package:modularity_contracts/modularity_contracts.dart';

import 'recording_binder.dart';

class ModuleBindingsSnapshot {
  ModuleBindingsSnapshot({
    required this.moduleType,
    required this.privateDependencies,
    required this.publicDependencies,
    required this.warnings,
  });

  final Type moduleType;
  final List<DependencyRecord> privateDependencies;
  final List<DependencyRecord> publicDependencies;
  final List<String> warnings;

  bool get hasBindings =>
      privateDependencies.isNotEmpty || publicDependencies.isNotEmpty;
}

class ModuleBindingsAnalyzer {
  final Map<Type, ModuleBindingsSnapshot> _cache = {};
  final Map<Type, RecordingBinder> _binderCache = {};

  ModuleBindingsSnapshot analyze(Module module) {
    return _analyze(module, <Type>{});
  }

  ModuleBindingsSnapshot _analyze(Module module, Set<Type> stack) {
    final type = module.runtimeType;

    if (_cache.containsKey(type)) {
      return _cache[type]!;
    }

    if (stack.contains(type)) {
      final cycle = [...stack, type].map((t) => t.toString()).join(' -> ');
      throw StateError('Circular module imports detected: $cycle');
    }

    final imports = module.imports;
    final newStack = {...stack, type};

    final importBinders = <RecordingBinder>[];
    for (final importModule in imports) {
      final snapshot = _analyze(importModule, newStack);
      final binder = _binderCache[snapshot.moduleType];
      if (binder != null) {
        importBinders.add(binder);
      }
    }

    final binder = RecordingBinder(imports: importBinders);
    _binderCache[type] = binder;
    final warnings = <String>[];

    void runPhase(String phase, void Function() action) {
      try {
        action();
      } catch (error) {
        final message =
            'GraphVisualizer: $type $phase() analysis failed: $error';
        warnings.add(message);
        print(message);
      }
    }

    runPhase('binds', () => module.binds(binder));

    binder.enableExportMode();
    runPhase('exports', () => module.exports(binder));
    binder.disableExportMode();
    binder.sealPublicScope();

    final snapshot = ModuleBindingsSnapshot(
      moduleType: type,
      privateDependencies: binder.privateDependencies,
      publicDependencies: binder.publicDependencies,
      warnings: List.unmodifiable(warnings),
    );

    _cache[type] = snapshot;
    return snapshot;
  }
}
