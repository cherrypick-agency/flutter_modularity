import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:modularity_core/modularity_core.dart';

import '../modularity.dart';

/// Snapshot of a retained module entry for debugging purposes.
///
/// Provides visibility into the retention cache state without exposing
/// mutable internal state.
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
    ModalRoute<dynamic>? route,
    FutureOr<void> Function()? onRouteTerminated,
    int refCount = 0,
  })  : refCount = refCount,
        moduleType = controller.module.runtimeType {
    attachRoute(
      route: route,
      onRouteTerminated: onRouteTerminated,
    );
  }

  final ModuleController controller;
  final ModuleRetentionPolicy policy;
  final Type moduleType;
  int refCount;
  DateTime lastAccessed;
  bool _disposed = false;
  ModalRoute<dynamic>? _route;
  FutureOr<void> Function()? _onRouteTerminated;
  bool _routeNotified = false;
  int _routeToken = 0;

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _unsubscribeRoute();
    await controller.dispose();
  }

  void attachRoute({
    ModalRoute<dynamic>? route,
    FutureOr<void> Function()? onRouteTerminated,
  }) {
    _onRouteTerminated = onRouteTerminated;
    if (route == null) {
      _routeToken++;
      _route = null;
      return;
    }
    if (_route == route) return;
    _route = route;
    _routeNotified = false;
    final currentToken = ++_routeToken;
    route.popped.whenComplete(() {
      if (_routeToken == currentToken) {
        unawaited(_notifyRouteTermination());
      }
    });
  }

  Future<void> _notifyRouteTermination() async {
    if (_routeNotified) return;
    _routeNotified = true;
    Modularity.log(
      ModuleLifecycleEvent.routeTerminated,
      moduleType,
      details: {'routeType': _route.runtimeType.toString()},
    );
    if (_onRouteTerminated != null) {
      await _onRouteTerminated!();
    }
  }

  void _unsubscribeRoute() {
    _routeToken++;
    _route = null;
  }
}

/// Cache for [ModuleController] instances with KeepAlive retention policy.
///
/// ## Retention Key vs Override Scope
///
/// **Important**: The retainer uses [retentionKey] for cache lookup, which is
/// independent of [ModuleOverrideScope]. This is by design:
///
/// - **retentionKey** determines cache identity (derived from module type,
///   route, arguments, and explicit key).
/// - **overrideScope** affects DI bindings within the module's dependency graph
///   but does NOT affect retention cache identity.
///
/// ### Implications
///
/// Two [ModuleScope] widgets of the same module type with:
/// - Same retentionKey but different overrideScopes → **share** the same
///   cached controller. The first scope's overrideScope wins.
/// - Different retentionKeys but same overrideScope → have **separate**
///   cached controllers.
///
/// If you need override-aware caching, provide explicit [retentionKey] that
/// incorporates the scope identity:
///
/// ```dart
/// ModuleScope(
///   module: MyModule(),
///   retentionPolicy: ModuleRetentionPolicy.keepAlive,
///   retentionKey: 'my-module-${overrideScope.hashCode}',
///   overrideScope: overrideScope,
///   child: ...,
/// )
/// ```
///
/// ## Thread Safety
///
/// This class is NOT thread-safe. All operations must be performed on the
/// main isolate.
class ModuleRetainer {
  final Map<Object, _ModuleRetainerEntry> _entries = {};

  bool contains(Object key) => _entries.containsKey(key);

  ModuleController? peek(Object key) => _entries[key]?.controller;

  ModuleController? acquire(Object key) {
    final entry = _entries[key];
    if (entry == null) return null;
    entry.refCount++;
    entry.lastAccessed = DateTime.now();
    Modularity.log(
      ModuleLifecycleEvent.reused,
      entry.moduleType,
      retentionKey: key,
      details: {'refCount': entry.refCount},
    );
    return entry.controller;
  }

  void register({
    required Object key,
    required ModuleController controller,
    ModuleRetentionPolicy policy = ModuleRetentionPolicy.keepAlive,
    int initialRefCount = 1,
    ModalRoute<dynamic>? route,
    FutureOr<void> Function()? onRouteTerminated,
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
      route: route,
      onRouteTerminated: onRouteTerminated,
    );
    _entries[key] = entry;
    Modularity.log(
      ModuleLifecycleEvent.registered,
      controller.module.runtimeType,
      retentionKey: key,
      details: {
        'policy': policy.name,
        'refCount': initialRefCount,
        'hasRoute': route != null,
      },
    );
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
    Modularity.log(
      ModuleLifecycleEvent.released,
      entry.moduleType,
      retentionKey: key,
      details: {
        'refCount': entry.refCount,
        'disposeIfOrphaned': disposeIfOrphaned
      },
    );
    if (disposeIfOrphaned && entry.refCount <= 0) {
      final removed = _entries.remove(key) ?? entry;
      await removed.dispose();
      Modularity.log(
        ModuleLifecycleEvent.disposed,
        removed.moduleType,
        retentionKey: key,
        details: {'reason': 'orphaned'},
      );
    }
  }

  Future<void> evict(Object key, {bool disposeController = true}) async {
    final entry = _entries.remove(key);
    if (entry == null) return;
    Modularity.log(
      ModuleLifecycleEvent.evicted,
      entry.moduleType,
      retentionKey: key,
      details: {'disposeController': disposeController},
    );
    if (disposeController) {
      await entry.dispose();
      Modularity.log(
        ModuleLifecycleEvent.disposed,
        entry.moduleType,
        retentionKey: key,
        details: {'reason': 'evicted'},
      );
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
