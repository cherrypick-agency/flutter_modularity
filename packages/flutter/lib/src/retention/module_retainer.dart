import 'package:modularity_core/modularity_core.dart';

class ModuleRetainerEntrySnapshot {
  ModuleRetainerEntrySnapshot({
    required this.key,
    required this.policy,
    required this.refCount,
    required this.lastAccessed,
    required this.moduleType,
  });

  final Object key;
  final ModuleRetentionPolicy policy;
  final int refCount;
  final DateTime lastAccessed;
  final Type moduleType;
}

class _ModuleRetainerEntry {
  _ModuleRetainerEntry({
    required this.controller,
    required this.policy,
    required this.lastAccessed,
    int refCount = 0,
  })  : refCount = refCount,
        moduleType = controller.module.runtimeType;

  final ModuleController controller;
  final ModuleRetentionPolicy policy;
  final Type moduleType;
  int refCount;
  DateTime lastAccessed;
  bool _disposed = false;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await controller.dispose();
  }
}

class ModuleRetainer {
  final Map<Object, _ModuleRetainerEntry> _entries = {};

  bool contains(Object key) => _entries.containsKey(key);

  ModuleController? peek(Object key) => _entries[key]?.controller;

  ModuleController? acquire(Object key) {
    final entry = _entries[key];
    if (entry == null) return null;
    entry.refCount++;
    entry.lastAccessed = DateTime.now();
    return entry.controller;
  }

  void register({
    required Object key,
    required ModuleController controller,
    ModuleRetentionPolicy policy = ModuleRetentionPolicy.keepAlive,
    int initialRefCount = 1,
  }) {
    if (_entries.containsKey(key)) {
      throw StateError(
        'Retention key "$key" is already registered. '
        'Call release/evict before registering again.',
      );
    }
    final entry = _ModuleRetainerEntry(
      controller: controller,
      policy: policy,
      lastAccessed: DateTime.now(),
      refCount: initialRefCount,
    );
    _entries[key] = entry;
  }

  Future<void> release(
    Object key, {
    bool disposeIfOrphaned = false,
  }) async {
    final entry = _entries[key];
    if (entry == null) return;
    if (entry.refCount > 0) {
      entry.refCount--;
    }
    if (disposeIfOrphaned && entry.refCount <= 0) {
      final removed = _entries.remove(key) ?? entry;
      await removed.dispose();
    }
  }

  Future<void> evict(Object key, {bool disposeController = true}) async {
    final entry = _entries.remove(key);
    if (entry == null) return;
    if (disposeController) {
      await entry.dispose();
    }
  }

  List<ModuleRetainerEntrySnapshot> debugSnapshot() {
    return _entries.entries
        .map(
          (e) => ModuleRetainerEntrySnapshot(
            key: e.key,
            policy: e.value.policy,
            refCount: e.value.refCount,
            lastAccessed: e.value.lastAccessed,
            moduleType: e.value.moduleType,
          ),
        )
        .toList(growable: false);
  }
}
