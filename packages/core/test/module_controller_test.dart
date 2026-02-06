import 'dart:async';
import 'package:modularity_core/modularity_core.dart';
import 'package:test/test.dart';

class PublicService {}

class PrivateImpl {}

class HotReloadFactory {
  HotReloadFactory(this.version);
  final int version;
}

class ProviderModule extends Module {
  @override
  void binds(Binder i) {
    i.registerLazySingleton<PublicService>(() => PublicService());
  }

  @override
  void exports(Binder i) {
    i.registerLazySingleton<PublicService>(() => i.get<PublicService>());
  }
}

class ConsumerModule extends Module {
  PublicService? resolved;

  @override
  List<Module> get imports => [ProviderModule()];

  @override
  List<Type> get expects => [PublicService];

  @override
  void binds(Binder i) {
    resolved = i.get<PublicService>();
    i.registerSingleton<PublicService>(resolved!);
  }
}

class MissingDependencyModule extends Module {
  @override
  List<Type> get expects => [PublicService];

  @override
  void binds(Binder i) {}
}

class LifecycleOrderModule extends Module {
  final List<String> callOrder = [];

  @override
  void binds(Binder i) {
    callOrder.add('binds');
    i.registerLazySingleton<PrivateImpl>(() => PrivateImpl());
  }

  @override
  void exports(Binder i) {
    callOrder.add('exports');
    i.registerLazySingleton<PublicService>(() => PublicService());
  }

  @override
  Future<void> onInit() async {
    callOrder.add('onInit');
  }
}

class FailingBindsModule extends Module {
  @override
  void binds(Binder i) {
    throw Exception('binds error');
  }
}

class FailingOnInitModule extends Module {
  @override
  void binds(Binder i) {
    i.registerLazySingleton<PrivateImpl>(() => PrivateImpl());
  }

  @override
  Future<void> onInit() async {
    throw Exception('onInit error');
  }
}

class _TestInterceptor implements ModuleInterceptor {
  final List<String> events = [];

  @override
  void onInit(Module module) => events.add('onInit:${module.runtimeType}');

  @override
  void onLoaded(Module module) => events.add('onLoaded:${module.runtimeType}');

  @override
  void onError(Module module, Object error) =>
      events.add('onError:${module.runtimeType}');

  @override
  void onDispose(Module module) =>
      events.add('onDispose:${module.runtimeType}');
}

class OverridableModule extends Module {
  @override
  void binds(Binder i) {
    i.registerLazySingleton<PublicService>(() => PublicService());
  }

  @override
  void exports(Binder i) {
    i.registerLazySingleton<PublicService>(() => i.get<PublicService>());
  }
}

class MockPublicService extends PublicService {}

class ConfigData {
  ConfigData(this.value);
  final String value;
}

class ConfigurableModule extends Module implements Configurable<ConfigData> {
  ConfigData? config;

  @override
  void configure(ConfigData args) {
    config = args;
  }

  @override
  void binds(Binder i) {
    i.registerSingleton<ConfigData>(config!);
  }
}

class CircularA extends Module {
  @override
  List<Module> get imports => [CircularB()];

  @override
  void binds(Binder i) {}
}

class CircularB extends Module {
  @override
  List<Module> get imports => [CircularA()];

  @override
  void binds(Binder i) {}
}

class HotReloadModule extends Module {
  int bindsCount = 0;

  @override
  void binds(Binder i) {
    bindsCount++;
    i.registerLazySingleton<PublicService>(() => PublicService());
    i.registerFactory<HotReloadFactory>(() => HotReloadFactory(bindsCount));
  }
}

class ChildOverridesModule extends Module {
  @override
  void binds(Binder i) {
    i.registerLazySingleton<PublicService>(() => PublicService());
  }

  @override
  void exports(Binder i) {
    i.registerLazySingleton<PublicService>(() => i.get<PublicService>());
  }
}

class ParentOverridesModule extends Module {
  PublicService? resolved;

  @override
  List<Module> get imports => [ChildOverridesModule()];

  @override
  void binds(Binder i) {
    resolved = i.get<PublicService>();
  }
}

class MockService extends PublicService {}

class AnotherMockService extends PublicService {}

void main() {
  group('ModuleRegistryKey', () {
    test('equal when same type and null overrideScope', () {
      final key1 = ModuleRegistryKey(moduleType: ProviderModule);
      final key2 = ModuleRegistryKey(moduleType: ProviderModule);

      expect(key1, equals(key2));
      expect(key1.hashCode, equals(key2.hashCode));
    });

    test('equal when same type and identical overrideScope', () {
      final scope = ModuleOverrideScope(selfOverrides: (binder) {});
      final key1 = ModuleRegistryKey(
        moduleType: ProviderModule,
        overrideScope: scope,
      );
      final key2 = ModuleRegistryKey(
        moduleType: ProviderModule,
        overrideScope: scope,
      );

      expect(key1, equals(key2));
      expect(key1.hashCode, equals(key2.hashCode));
    });

    test('not equal when different types', () {
      final key1 = ModuleRegistryKey(moduleType: ProviderModule);
      final key2 = ModuleRegistryKey(moduleType: ConsumerModule);

      expect(key1, isNot(equals(key2)));
    });

    test('not equal when different overrideScope instances', () {
      final scope1 = ModuleOverrideScope(selfOverrides: (binder) {});
      final scope2 = ModuleOverrideScope(selfOverrides: (binder) {});
      final key1 = ModuleRegistryKey(
        moduleType: ProviderModule,
        overrideScope: scope1,
      );
      final key2 = ModuleRegistryKey(
        moduleType: ProviderModule,
        overrideScope: scope2,
      );

      expect(key1, isNot(equals(key2)));
    });

    test('not equal when one has null overrideScope and other does not', () {
      final scope = ModuleOverrideScope(selfOverrides: (binder) {});
      final key1 = ModuleRegistryKey(moduleType: ProviderModule);
      final key2 = ModuleRegistryKey(
        moduleType: ProviderModule,
        overrideScope: scope,
      );

      expect(key1, isNot(equals(key2)));
    });

    test('works correctly as Map key', () {
      final registry = <ModuleRegistryKey, String>{};
      final scope = ModuleOverrideScope(selfOverrides: (binder) {});

      final key1 = ModuleRegistryKey(moduleType: ProviderModule);
      final key2 = ModuleRegistryKey(
        moduleType: ProviderModule,
        overrideScope: scope,
      );
      final key3 = ModuleRegistryKey(moduleType: ConsumerModule);

      registry[key1] = 'default';
      registry[key2] = 'with-scope';
      registry[key3] = 'consumer';

      expect(registry.length, equals(3));
      expect(registry[key1], equals('default'));
      expect(registry[key2], equals('with-scope'));
      expect(registry[key3], equals('consumer'));

      // Same key retrieves same value
      final key1Copy = ModuleRegistryKey(moduleType: ProviderModule);
      expect(registry[key1Copy], equals('default'));
    });
  });

  group('ModuleController + SimpleBinder integration', () {
    test('imports expose exported dependencies to consumers', () async {
      final registry = <ModuleRegistryKey, ModuleController>{};
      final consumerController = ModuleController(ConsumerModule());

      await consumerController.initialize(registry);

      expect(
        consumerController.binder.get<PublicService>(),
        isA<PublicService>(),
      );
      final module = consumerController.module as ConsumerModule;
      expect(module.resolved, isNotNull);
    });

    test('throws when expects are missing in imports/parent', () async {
      final registry = <ModuleRegistryKey, ModuleController>{};
      final controller = ModuleController(MissingDependencyModule());

      await expectLater(
        () => controller.initialize(registry),
        throwsA(isA<Exception>()),
      );
    });

    test('hotReload rebinds without duplicate export errors', () async {
      final registry = <ModuleRegistryKey, ModuleController>{};
      final controller = ModuleController(ConsumerModule());

      await controller.initialize(registry);
      controller.hotReload();

      expect(controller.binder.get<PublicService>(), isA<PublicService>());
    });

    test(
      'hotReload preserves singleton instances and updates factories',
      () async {
        final registry = <ModuleRegistryKey, ModuleController>{};
        final controller = ModuleController(HotReloadModule());

        await controller.initialize(registry);

        final singleton1 = controller.binder.get<PublicService>();
        final factory1 = controller.binder.get<HotReloadFactory>();
        expect(factory1.version, equals(1));

        controller.hotReload();

        final singleton2 = controller.binder.get<PublicService>();
        final factory2 = controller.binder.get<HotReloadFactory>();

        expect(singleton2, same(singleton1));
        expect(factory2.version, equals(2));
      },
    );

    test('child override scope applies overrides to imports', () async {
      final registry = <ModuleRegistryKey, ModuleController>{};
      final overrideScope = ModuleOverrideScope(
        children: {
          ChildOverridesModule: ModuleOverrideScope(
            selfOverrides: (binder) {
              binder.registerLazySingleton<PublicService>(() => MockService());
            },
          ),
        },
      );

      final controller = ModuleController(
        ParentOverridesModule(),
        overrideScopeTree: overrideScope,
      );

      await controller.initialize(registry);
      final module = controller.module as ParentOverridesModule;

      expect(module.resolved, isA<MockService>());
    });

    test('child override scope stays isolated per controller', () async {
      final registry = <ModuleRegistryKey, ModuleController>{};

      final overrideScopeA = ModuleOverrideScope(
        children: {
          ChildOverridesModule: ModuleOverrideScope(
            selfOverrides: (binder) {
              binder.registerLazySingleton<PublicService>(() => MockService());
            },
          ),
        },
      );

      final overrideScopeB = ModuleOverrideScope(
        children: {
          ChildOverridesModule: ModuleOverrideScope(
            selfOverrides: (binder) {
              binder.registerLazySingleton<PublicService>(
                () => AnotherMockService(),
              );
            },
          ),
        },
      );

      final controllerA = ModuleController(
        ParentOverridesModule(),
        overrideScopeTree: overrideScopeA,
      );
      final controllerB = ModuleController(
        ParentOverridesModule(),
        overrideScopeTree: overrideScopeB,
      );

      await controllerA.initialize(registry);
      await controllerB.initialize(registry);

      expect(
        (controllerA.module as ParentOverridesModule).resolved,
        isA<MockService>(),
      );
      expect(
        (controllerB.module as ParentOverridesModule).resolved,
        isA<AnotherMockService>(),
      );

      await controllerA.dispose();
      await controllerB.dispose();
    });
  });

  group('ModuleController lifecycle', () {
    test('binds called before exports before onInit', () async {
      final module = LifecycleOrderModule();
      final controller = ModuleController(module);
      final registry = <ModuleRegistryKey, ModuleController>{};

      await controller.initialize(registry);

      expect(module.callOrder, equals(['binds', 'exports', 'onInit']));
    });

    test('status transitions initial -> loading -> loaded', () async {
      final module = LifecycleOrderModule();
      final controller = ModuleController(module);
      final registry = <ModuleRegistryKey, ModuleController>{};

      final statuses = <ModuleStatus>[];
      controller.status.listen(statuses.add);

      expect(controller.currentStatus, equals(ModuleStatus.initial));

      await controller.initialize(registry);

      expect(statuses, contains(ModuleStatus.loading));
      expect(controller.currentStatus, equals(ModuleStatus.loaded));
    });

    test('status error on exception in binds', () async {
      final controller = ModuleController(FailingBindsModule());
      final registry = <ModuleRegistryKey, ModuleController>{};

      await expectLater(
        () => controller.initialize(registry),
        throwsA(isA<Exception>()),
      );

      expect(controller.currentStatus, equals(ModuleStatus.error));
      expect(controller.lastError, isNotNull);
    });

    test('status error on exception in onInit', () async {
      final controller = ModuleController(FailingOnInitModule());
      final registry = <ModuleRegistryKey, ModuleController>{};

      await expectLater(
        () => controller.initialize(registry),
        throwsA(isA<Exception>()),
      );

      expect(controller.currentStatus, equals(ModuleStatus.error));
    });
  });

  group('ModuleController interceptors', () {
    test('interceptors receive lifecycle events', () async {
      final interceptor = _TestInterceptor();
      final module = LifecycleOrderModule();
      final controller = ModuleController(module, interceptors: [interceptor]);
      final registry = <ModuleRegistryKey, ModuleController>{};

      await controller.initialize(registry);

      expect(interceptor.events, contains('onInit:LifecycleOrderModule'));
      expect(interceptor.events, contains('onLoaded:LifecycleOrderModule'));
    });

    test('interceptors receive onError on failure', () async {
      final interceptor = _TestInterceptor();
      final controller = ModuleController(
        FailingBindsModule(),
        interceptors: [interceptor],
      );
      final registry = <ModuleRegistryKey, ModuleController>{};

      await expectLater(
        () => controller.initialize(registry),
        throwsA(isA<Exception>()),
      );

      expect(interceptor.events, contains('onError:FailingBindsModule'));
    });

    test('interceptors receive onDispose', () async {
      final interceptor = _TestInterceptor();
      final module = LifecycleOrderModule();
      final controller = ModuleController(module, interceptors: [interceptor]);
      final registry = <ModuleRegistryKey, ModuleController>{};

      await controller.initialize(registry);
      await controller.dispose();

      expect(interceptor.events, contains('onDispose:LifecycleOrderModule'));
    });
  });

  group('ModuleController overrides', () {
    test('overrides applied after binds before exports', () async {
      final controller = ModuleController(
        OverridableModule(),
        overrides: (binder) {
          binder.registerSingleton<PublicService>(MockPublicService());
        },
      );
      final registry = <ModuleRegistryKey, ModuleController>{};

      await controller.initialize(registry);

      expect(controller.binder.get<PublicService>(), isA<MockPublicService>());
    });
  });

  group('ModuleController configurable', () {
    test('configure called with args', () async {
      final module = ConfigurableModule();
      final controller = ModuleController(module);
      final registry = <ModuleRegistryKey, ModuleController>{};

      controller.configure(ConfigData('test_value'));
      await controller.initialize(registry);

      expect(module.config?.value, equals('test_value'));
      expect(controller.binder.get<ConfigData>().value, equals('test_value'));
    });
  });

  group('ModuleController dispose', () {
    test('dispose clears binder and updates status', () async {
      final module = LifecycleOrderModule();
      final controller = ModuleController(module);
      final registry = <ModuleRegistryKey, ModuleController>{};

      await controller.initialize(registry);
      await controller.dispose();

      expect(controller.currentStatus, equals(ModuleStatus.disposed));
    });
  });

  group('ModuleController circular imports', () {
    test('throws on circular import A -> B -> A', () async {
      final controller = ModuleController(CircularA());
      final registry = <ModuleRegistryKey, ModuleController>{};

      await expectLater(
        () => controller.initialize(registry),
        throwsA(isA<Exception>()),
      );
    });
  });
}
