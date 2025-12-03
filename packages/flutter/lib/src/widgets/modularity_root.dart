import 'package:flutter/widgets.dart';
import 'package:modularity_core/modularity_core.dart';

import '../retention/module_retainer.dart';

/// Корневой виджет фреймворка.
/// Хранит глобальный реестр активных модулей и конфигурацию DI.
class ModularityRoot extends InheritedWidget {
  final Map<ModuleRegistryKey, ModuleController> _registry = {};
  final BinderFactory binderFactory;
  final WidgetBuilder? defaultLoadingBuilder;
  final Widget Function(BuildContext, Object? error, VoidCallback retry)?
      defaultErrorBuilder;
  final ModuleRetainer retainer;

  ModularityRoot({
    Key? key,
    required Widget child,
    BinderFactory? binderFactory,
    this.defaultLoadingBuilder,
    this.defaultErrorBuilder,
    ModuleRetainer? retainer,
  })  : binderFactory = binderFactory ?? SimpleBinderFactory(),
        retainer = retainer ?? ModuleRetainer(),
        super(key: key, child: child);

  @override
  bool updateShouldNotify(ModularityRoot oldWidget) =>
      binderFactory != oldWidget.binderFactory ||
      defaultLoadingBuilder != oldWidget.defaultLoadingBuilder ||
      defaultErrorBuilder != oldWidget.defaultErrorBuilder ||
      retainer != oldWidget.retainer;

  static ModularityRoot of(BuildContext context) {
    final root = context.dependOnInheritedWidgetOfExactType<ModularityRoot>();
    if (root == null) {
      throw Exception(
          'ModularityRoot not found. Please wrap your app in ModularityRoot (or ModularApp).');
    }
    return root;
  }

  static Map<ModuleRegistryKey, ModuleController> registryOf(
          BuildContext context) =>
      of(context)._registry;
  static BinderFactory binderFactoryOf(BuildContext context) =>
      of(context).binderFactory;

  static WidgetBuilder? defaultLoadingBuilderOf(BuildContext context) =>
      of(context).defaultLoadingBuilder;
  static Widget Function(BuildContext, Object?, VoidCallback)?
      defaultErrorBuilderOf(BuildContext context) =>
          of(context).defaultErrorBuilder;

  static ModuleRetainer retainerOf(BuildContext context) =>
      of(context).retainer;
}
