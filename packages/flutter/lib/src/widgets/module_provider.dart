import 'package:flutter/widgets.dart';
import 'package:modularity_core/modularity_core.dart';

/// Inherited widget that exposes a [ModuleController] and its [Binder] to
/// descendant widgets.
///
/// Typically inserted by [ModuleScope]; consumers obtain the [Binder] via
/// [ModuleProvider.of] or retrieve the typed [Module] via
/// [ModuleProvider.moduleOf].
class ModuleProvider extends InheritedWidget {
  /// Create a [ModuleProvider] that exposes [controller] to [child].
  const ModuleProvider({
    super.key,
    required this.controller,
    required super.child,
  });

  /// Controller that owns the DI [Binder] and the [Module] lifecycle.
  final ModuleController controller;

  @override
  bool updateShouldNotify(ModuleProvider oldWidget) {
    return controller != oldWidget.controller;
  }

  /// Получает [Binder] из ближайшего модуля.
  /// Используется для получения зависимостей вручную:
  /// `ModuleProvider.of(context).get<Service>()`
  /// `ModuleProvider.of(context).parent<Service>()`
  static Binder of(BuildContext context, {bool listen = true}) {
    final provider = listen
        ? context.dependOnInheritedWidgetOfExactType<ModuleProvider>()
        : context.getInheritedWidgetOfExactType<ModuleProvider>();

    if (provider == null) {
      throw ModuleConfigurationException(
        'ModuleProvider not found in context.',
      );
    }
    return provider.controller.binder;
  }

  /// Получает сам модуль типа [M] из контекста.
  static M moduleOf<M extends Module>(
    BuildContext context, {
    bool listen = true,
  }) {
    final provider = listen
        ? context.dependOnInheritedWidgetOfExactType<ModuleProvider>()
        : context.getInheritedWidgetOfExactType<ModuleProvider>();

    if (provider == null) {
      throw ModuleConfigurationException(
        'ModuleProvider not found in context.',
      );
    }

    if (provider.controller.module is! M) {
      throw ModuleConfigurationException(
        'Nearest module is ${provider.controller.module.runtimeType}, but expected $M.',
      );
    }

    return provider.controller.module as M;
  }
}
