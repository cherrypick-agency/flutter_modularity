import 'package:modularity_core/modularity_core.dart';
import 'package:test/test.dart';

class TestInterceptor implements ModuleInterceptor {
  final List<String> log = [];

  @override
  void onInit(Module module) => log.add('onInit');

  @override
  void onLoaded(Module module) => log.add('onLoaded');

  @override
  void onError(Module module, Object error) => log.add('onError');

  @override
  void onDispose(Module module) => log.add('onDispose');
}

class TestModule extends Module {
  @override
  void binds(Binder i) {}
}

class ErrorModule extends Module {
  @override
  void binds(Binder i) {
    throw Exception('Bind failed');
  }
}

void main() {
  group('Module Interceptors', () {
    test('intercepts successful lifecycle', () async {
      final interceptor = TestInterceptor();
      final controller = ModuleController(
        TestModule(),
        interceptors: [interceptor],
      );

      await controller.initialize(<ModuleRegistryKey, ModuleController>{});
      expect(interceptor.log, ['onInit', 'onLoaded']);

      await controller.dispose();
      expect(interceptor.log, ['onInit', 'onLoaded', 'onDispose']);
    });

    test('intercepts error lifecycle', () async {
      final interceptor = TestInterceptor();
      final controller = ModuleController(
        ErrorModule(),
        interceptors: [interceptor],
      );

      try {
        await controller.initialize(<ModuleRegistryKey, ModuleController>{});
      } catch (_) {}

      expect(interceptor.log, ['onInit', 'onError']);
    });
  });
}
