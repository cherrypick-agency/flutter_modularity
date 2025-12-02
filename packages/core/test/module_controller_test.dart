import 'dart:async';
import 'package:modularity_core/modularity_core.dart';
import 'package:test/test.dart';

class PublicService {}

class PrivateImpl {}

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
  final String value;
  ConfigData(this.value);
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

void main() {
  group('ModuleController + SimpleBinder integration', () {
    test('imports expose exported dependencies to consumers', () async {
      final registry = <Type, ModuleController>{};
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
      final registry = <Type, ModuleController>{};
      final controller = ModuleController(MissingDependencyModule());

      await expectLater(
        () => controller.initialize(registry),
        throwsA(isA<Exception>()),
      );
    });

    test('hotReload rebinds without duplicate export errors', () async {
      final registry = <Type, ModuleController>{};
      final controller = ModuleController(ConsumerModule());

      await controller.initialize(registry);
      controller.hotReload();

      expect(
        controller.binder.get<PublicService>(),
        isA<PublicService>(),
      );
    });
  });

  group('ModuleController lifecycle', () {
    test('binds called before exports before onInit', () async {
      final module = LifecycleOrderModule();
      final controller = ModuleController(module);
      final registry = <Type, ModuleController>{};

      await controller.initialize(registry);

      expect(module.callOrder, equals(['binds', 'exports', 'onInit']));
    });

    test('status transitions initial -> loading -> loaded', () async {
      final module = LifecycleOrderModule();
      final controller = ModuleController(module);
      final registry = <Type, ModuleController>{};

      final statuses = <ModuleStatus>[];
      controller.status.listen(statuses.add);

      expect(controller.currentStatus, equals(ModuleStatus.initial));

      await controller.initialize(registry);

      expect(statuses, contains(ModuleStatus.loading));
      expect(controller.currentStatus, equals(ModuleStatus.loaded));
    });

    test('status error on exception in binds', () async {
      final controller = ModuleController(FailingBindsModule());
      final registry = <Type, ModuleController>{};

      await expectLater(
        () => controller.initialize(registry),
        throwsA(isA<Exception>()),
      );

      expect(controller.currentStatus, equals(ModuleStatus.error));
      expect(controller.lastError, isNotNull);
    });

    test('status error on exception in onInit', () async {
      final controller = ModuleController(FailingOnInitModule());
      final registry = <Type, ModuleController>{};

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
      final controller = ModuleController(
        module,
        interceptors: [interceptor],
      );
      final registry = <Type, ModuleController>{};

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
      final registry = <Type, ModuleController>{};

      await expectLater(
        () => controller.initialize(registry),
        throwsA(isA<Exception>()),
      );

      expect(interceptor.events, contains('onError:FailingBindsModule'));
    });

    test('interceptors receive onDispose', () async {
      final interceptor = _TestInterceptor();
      final module = LifecycleOrderModule();
      final controller = ModuleController(
        module,
        interceptors: [interceptor],
      );
      final registry = <Type, ModuleController>{};

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
      final registry = <Type, ModuleController>{};

      await controller.initialize(registry);

      expect(
        controller.binder.get<PublicService>(),
        isA<MockPublicService>(),
      );
    });
  });

  group('ModuleController configurable', () {
    test('configure called with args', () async {
      final module = ConfigurableModule();
      final controller = ModuleController(module);
      final registry = <Type, ModuleController>{};

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
      final registry = <Type, ModuleController>{};

      await controller.initialize(registry);
      await controller.dispose();

      expect(controller.currentStatus, equals(ModuleStatus.disposed));
    });
  });

  group('ModuleController circular imports', () {
    test('throws on circular import A -> B -> A', () async {
      final controller = ModuleController(CircularA());
      final registry = <Type, ModuleController>{};

      await expectLater(
        () => controller.initialize(registry),
        throwsA(isA<Exception>()),
      );
    });
  });
}
