import 'package:get_it/get_it.dart';
import 'package:modularity_contracts/modularity_contracts.dart';
import 'package:modularity_get_it/modularity_get_it.dart';
import 'package:test/test.dart';

void main() {
  group('GetItBinder', () {
    tearDown(() async {
      await GetIt.instance.reset();
    });

    test('Isolated Mode (default): registers in new instance', () {
      final binder =
          GetItBinderFactory(useGlobalInstance: false).create() as GetItBinder;

      binder.registerSingleton<String>('isolated');

      expect(binder.get<String>(), 'isolated');
      // Should NOT be in global GetIt
      expect(GetIt.instance.isRegistered<String>(), isFalse);
    });

    test('Global Mode: registers in global instance', () {
      final binder =
          GetItBinderFactory(useGlobalInstance: true).create() as GetItBinder;

      binder.registerSingleton<String>('global');

      expect(binder.get<String>(), 'global');
      // Should BE in global GetIt
      expect(GetIt.instance.isRegistered<String>(), isTrue);
      expect(GetIt.instance<String>(), 'global');
    });

    test('Global Mode: reset() clears ONLY registered types', () async {
      final binder =
          GetItBinderFactory(useGlobalInstance: true).create() as GetItBinder;

      // Register something externally
      GetIt.instance.registerSingleton<int>(42);

      // Register via binder
      binder.registerSingleton<String>('mine');

      expect(GetIt.instance.isRegistered<int>(), isTrue);
      expect(GetIt.instance.isRegistered<String>(), isTrue);

      await binder.reset();

      // 'mine' should be gone
      expect(GetIt.instance.isRegistered<String>(), isFalse);
      // 'int' should stay
      expect(GetIt.instance.isRegistered<int>(), isTrue);
    });

    test('preserve strategy keeps existing singleton instances', () {
      final binder = GetItBinder();
      binder.registerLazySingleton<String>(() => 'v1');
      final first = binder.get<String>();

      binder.runWithStrategy(RegistrationStrategy.preserveExisting, () {
        binder.registerLazySingleton<String>(() => 'v2');
      });

      final second = binder.get<String>();
      expect(second, same(first));
    });

    test('preserve strategy updates factory delegates', () {
      final binder = GetItBinder();
      binder.registerFactory<int>(() => 1);
      expect(binder.get<int>(), equals(1));

      binder.runWithStrategy(RegistrationStrategy.preserveExisting, () {
        binder.registerFactory<int>(() => 2);
      });

      expect(binder.get<int>(), equals(2));
    });
  });
}
