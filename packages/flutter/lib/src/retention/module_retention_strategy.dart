import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:modularity_core/modularity_core.dart';

import '../modularity.dart';
import 'module_retainer.dart';

typedef ControllerGetter = ModuleController? Function();
typedef ControllerRelease = Future<void> Function(
    {required bool disposeController});

class ModuleRetentionBinding {
  ModuleRetentionBinding({
    required this.context,
    required this.module,
    required this.retentionKey,
    required this.controllerGetter,
    required this.releaseController,
    required this.retainer,
    this.route,
    RouteObserver<ModalRoute>? observer,
  });

  final BuildContext context;
  final Module module;
  final Object retentionKey;
  final ModuleRetainer retainer;
  final ControllerGetter controllerGetter;
  final ControllerRelease releaseController;
  final ModalRoute<dynamic>? route;
  RouteObserver<ModalRoute> get observer => Modularity.observer;
}

abstract class ModuleRetentionStrategy {
  ModuleRetentionStrategy(this.binding);

  final ModuleRetentionBinding binding;

  ModuleController? reuseExisting();

  void onControllerCreated(ModuleController controller);

  Future<void> onStateDispose();

  Future<void> disposeNow();

  Future<void> onRetry();

  void didChangeDependencies();
}

class StrictRetentionStrategy extends ModuleRetentionStrategy {
  StrictRetentionStrategy(super.binding);

  @override
  void didChangeDependencies() {}

  @override
  ModuleController? reuseExisting() => null;

  @override
  void onControllerCreated(ModuleController controller) {}

  @override
  Future<void> onRetry() => binding.releaseController(disposeController: true);

  @override
  Future<void> disposeNow() =>
      binding.releaseController(disposeController: true);

  @override
  Future<void> onStateDispose() =>
      binding.releaseController(disposeController: true);
}

class KeepAliveRetentionStrategy extends ModuleRetentionStrategy {
  KeepAliveRetentionStrategy(super.binding);

  bool _registered = false;
  bool _released = false;
  bool _routeTerminationHandled = false;

  @override
  void didChangeDependencies() {}

  @override
  ModuleController? reuseExisting() {
    if (_routeTerminationHandled) {
      return null;
    }
    final controller = binding.retainer.acquire(binding.retentionKey);
    if (controller != null) {
      _registered = true;
      _released = false;
      _routeTerminationHandled = false;
    }
    return controller;
  }

  @override
  void onControllerCreated(ModuleController controller) {
    if (_routeTerminationHandled) {
      return;
    }
    if (_registered) return;
    binding.retainer.register(
      key: binding.retentionKey,
      controller: controller,
      policy: ModuleRetentionPolicy.keepAlive,
      route: binding.route,
      onRouteTerminated: _handleRouteTermination,
    );
    _registered = true;
    _released = false;
    _routeTerminationHandled = false;
  }

  @override
  Future<void> onRetry() async {
    if (_registered) {
      await binding.releaseController(disposeController: false);
      await binding.retainer.evict(binding.retentionKey);
    } else {
      await binding.releaseController(disposeController: true);
    }
    _registered = false;
    _released = false;
    _routeTerminationHandled = false;
  }

  @override
  Future<void> disposeNow() async => _evictRetainedController();

  @override
  Future<void> onStateDispose() async {
    if (!_registered) {
      await binding.releaseController(disposeController: true);
      return;
    }
    if (_released) return;
    _released = true;
    await binding.releaseController(disposeController: false);
    await binding.retainer.release(binding.retentionKey);
  }

  Future<void> _evictRetainedController() async {
    if (!_registered) {
      await binding.releaseController(disposeController: true);
      return;
    }
    await binding.releaseController(disposeController: false);
    await binding.retainer
        .evict(binding.retentionKey, disposeController: false);
    _registered = false;
    _released = true;
    _routeTerminationHandled = true;
  }

  void _handleRouteTermination() {
    if (_routeTerminationHandled) return;
    _routeTerminationHandled = true;
    unawaited(_evictRetainedController());
  }
}

class RouteBoundRetentionStrategy extends ModuleRetentionStrategy
    with RouteAware {
  RouteBoundRetentionStrategy(super.binding);

  ModalRoute? _route;
  bool _disposedByRoute = false;

  @override
  void didChangeDependencies() {
    final route = ModalRoute.of(binding.context);
    if (route == null) {
      return;
    }
    if (_route == route) {
      return;
    }
    if (_route != null) {
      Modularity.observer.unsubscribe(this);
    }
    _route = route;
    Modularity.observer.subscribe(this, route);
  }

  @override
  ModuleController? reuseExisting() => null;

  @override
  void onControllerCreated(ModuleController controller) {}

  @override
  Future<void> onRetry() async {
    _disposedByRoute = false;
    await binding.releaseController(disposeController: true);
  }

  @override
  Future<void> disposeNow() async {
    if (_disposedByRoute) return;
    _disposedByRoute = true;
    await binding.releaseController(disposeController: true);
  }

  @override
  Future<void> onStateDispose() async {
    Modularity.observer.unsubscribe(this);
    if (!_disposedByRoute) {
      await binding.releaseController(disposeController: true);
    }
  }

  @override
  void didPop() {
    disposeNow();
  }

  /// Called when the route is removed without popping.
  void didRemove() {
    disposeNow();
  }
}

ModuleRetentionStrategy buildStrategy(
  ModuleRetentionPolicy policy,
  ModuleRetentionBinding binding,
) {
  switch (policy) {
    case ModuleRetentionPolicy.routeBound:
      return RouteBoundRetentionStrategy(binding);
    case ModuleRetentionPolicy.keepAlive:
      return KeepAliveRetentionStrategy(binding);
    case ModuleRetentionPolicy.strict:
      return StrictRetentionStrategy(binding);
  }
}
