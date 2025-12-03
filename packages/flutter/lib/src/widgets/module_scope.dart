import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:modularity_core/modularity_core.dart';

import '../modularity.dart';
import '../retention/module_retention_strategy.dart';
import '../retention/retention_identity.dart';
import 'module_provider.dart';
import 'modularity_root.dart';

class ModuleScope<T extends Module> extends StatefulWidget {
  final T module;
  final Widget child;
  final dynamic args;
  final WidgetBuilder? loadingBuilder;
  final Widget Function(BuildContext, Object? error, VoidCallback retry)?
      errorBuilder;
  final ModuleRetentionPolicy retentionPolicy;
  final Object? retentionKey;
  final Map<String, Object?>? retentionExtras;
  @Deprecated('Use retentionPolicy/retentionKey instead')
  final bool disposeModule;
  final void Function(Binder)? overrides;
  final ModuleOverrideScope? overrideScope;

  const ModuleScope({
    Key? key,
    required this.module,
    required this.child,
    this.args,
    this.loadingBuilder,
    this.errorBuilder,
    this.retentionPolicy = ModuleRetentionPolicy.routeBound,
    this.retentionKey,
    this.retentionExtras,
    @Deprecated('Use retentionPolicy/retentionKey instead')
    this.disposeModule = true,
    this.overrides,
    this.overrideScope,
  }) : super(key: key);

  @override
  _ModuleScopeState<T> createState() => _ModuleScopeState<T>();
}

class _ModuleScopeState<T extends Module> extends State<ModuleScope<T>> {
  ModuleController? _controller;
  StreamSubscription? _statusSub;
  ModuleStatus _status = ModuleStatus.initial;
  Object? _error;
  late ModuleRetentionPolicy _policy;
  Object? _retentionKey;
  ModuleRetentionStrategy? _strategy;
  bool _retentionInitialized = false;

  @override
  void initState() {
    super.initState();
    _policy = _derivePolicy(widget);
  }

  @override
  void didUpdateWidget(covariant ModuleScope<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    assert(
      oldWidget.retentionPolicy == widget.retentionPolicy,
      'Changing retentionPolicy at runtime is not supported. '
      'Rebuild ModuleScope with a new instance instead.',
    );
    assert(
      oldWidget.retentionKey == widget.retentionKey,
      'Changing retentionKey at runtime is not supported.',
    );
    // ignore: deprecated_member_use_from_same_package
    assert(
      // ignore: deprecated_member_use_from_same_package
      oldWidget.disposeModule == widget.disposeModule,
      'Changing disposeModule at runtime is not supported.',
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureStrategyInitialized();
    _strategy?.didChangeDependencies();
    _ensureController();
  }

  void _createAndInitController() {
    final factory = ModularityRoot.binderFactoryOf(context);

    // Scope Chaining: Find Parent Binder
    Binder? parentBinder;
    try {
      final parentProvider =
          context.dependOnInheritedWidgetOfExactType<ModuleProvider>();
      parentBinder = parentProvider?.controller.binder;
    } catch (_) {}

    // Create Binder with parent
    final binder = factory.create(parentBinder);

    final controller = ModuleController(
      widget.module,
      binder: binder,
      binderFactory: factory,
      overrides: widget.overrides,
      overrideScopeTree: widget.overrideScope,
      interceptors: Modularity.interceptors, // Pass global interceptors
    );

    // Конфигурируем (args передаются в configure(T args))
    if (widget.args != null) {
      controller.configure(widget.args);
    }

    _attachController(controller, runInitialize: true);
  }

  void _attachController(
    ModuleController controller, {
    required bool runInitialize,
  }) {
    _controller = controller;
    _init(runInitialize: runInitialize);
  }

  void _init({required bool runInitialize}) {
    final controller = _controller;
    if (controller == null) return;

    _status = controller.currentStatus;
    if (_status == ModuleStatus.error) {
      _error = controller.lastError;
    }

    _statusSub?.cancel();
    _statusSub = controller.status.listen((status) {
      if (mounted) {
        setState(() {
          _status = status;
          if (status == ModuleStatus.error) {
            _error = controller.lastError;
          }
        });
      }
    });

    if (runInitialize) {
      final registry = ModularityRoot.registryOf(context);
      controller.initialize(registry).catchError((_) {
        // Ошибки ловим в listen
      });
    }
  }

  void _ensureStrategyInitialized() {
    if (_retentionInitialized && _strategy != null) {
      return;
    }

    final parentKey = _RetentionKeyScope.maybeOf(context);
    final derivedKey = deriveRetentionKey(
      module: widget.module,
      context: context,
      explicitKey: widget.retentionKey,
      parentKey: parentKey,
      args: widget.args,
      extras: widget.retentionExtras,
    );
    _retentionKey = derivedKey;

    final binding = ModuleRetentionBinding(
      context: context,
      module: widget.module,
      retentionKey: derivedKey,
      controllerGetter: () => _controller,
      releaseController: ({required bool disposeController}) =>
          _releaseController(disposeController: disposeController),
    );

    _strategy = buildStrategy(_policy, binding);
    _retentionInitialized = true;
  }

  void _ensureController() {
    if (_controller != null) return;

    final reused = _strategy?.reuseExisting();
    if (reused != null) {
      _attachController(reused, runInitialize: false);
      return;
    }

    _createAndInitController();
    final controller = _controller;
    if (controller != null) {
      _strategy?.onControllerCreated(controller);
    }
  }

  Future<void> _releaseController({required bool disposeController}) async {
    final controller = _controller;
    if (controller == null) return;
    _statusSub?.cancel();
    _statusSub = null;
    _controller = null;
    if (disposeController) {
      await controller.dispose();
    }
  }

  ModuleRetentionPolicy _derivePolicy(ModuleScope<T> scope) {
    // ignore: deprecated_member_use_from_same_package
    if (!scope.disposeModule) {
      return ModuleRetentionPolicy.keepAlive;
    }
    return scope.retentionPolicy;
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _statusSub = null;
    final strategy = _strategy;
    _strategy = null;

    if (strategy != null) {
      unawaited(strategy.onStateDispose());
    } else {
      unawaited(_releaseController(disposeController: true));
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return const SizedBox.shrink();
    }

    final content = ModuleProvider(
      controller: controller,
      child: _buildContent(),
    );

    final key = _retentionKey;
    if (key == null) {
      return content;
    }

    return _RetentionKeyScope(
      value: key,
      child: content,
    );
  }

  Widget _buildContent() {
    switch (_status) {
      case ModuleStatus.initial:
      case ModuleStatus.loading:
        return _buildLoading();

      case ModuleStatus.error:
        return _buildError();

      case ModuleStatus.loaded:
        return widget.child;

      case ModuleStatus.disposed:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLoading() {
    if (widget.loadingBuilder != null) {
      return widget.loadingBuilder!(context);
    }

    final defaultBuilder = ModularityRoot.defaultLoadingBuilderOf(context);
    if (defaultBuilder != null) {
      return defaultBuilder(context);
    }

    // Agnostic Default
    return const Center(
      child: Text('Loading...', textDirection: TextDirection.ltr),
    );
  }

  Widget _buildError() {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, _error, _retry);
    }

    final defaultBuilder = ModularityRoot.defaultErrorBuilderOf(context);
    if (defaultBuilder != null) {
      return defaultBuilder(context, _error, _retry);
    }

    // Agnostic Default
    return Center(
      child: SingleChildScrollView(
        // Add scroll to prevent overflow
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Module Init Failed', textDirection: TextDirection.ltr),
            const SizedBox(height: 8),
            Text(_error.toString(), textDirection: TextDirection.ltr),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _retry,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Retry',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: Color(0xFF0000FF))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _retry() {
    unawaited(_handleRetry());
  }

  Future<void> _handleRetry() async {
    if (_strategy != null) {
      await _strategy!.onRetry();
    } else {
      await _releaseController(disposeController: true);
    }

    if (!mounted) return;

    setState(() {
      _status = ModuleStatus.initial;
      _error = null;
    });

    _ensureController();
  }
}

class _RetentionKeyScope extends InheritedWidget {
  const _RetentionKeyScope({
    required this.value,
    required super.child,
  });

  final Object value;

  static Object? maybeOf(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<_RetentionKeyScope>();
    return scope?.value;
  }

  @override
  bool updateShouldNotify(_RetentionKeyScope oldWidget) =>
      value != oldWidget.value;
}
