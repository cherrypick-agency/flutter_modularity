import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modularity_flutter/modularity_flutter.dart';
import 'package:modularity_flutter/src/retention/module_retainer.dart';

class LifecycleModule extends Module {
  int initCount = 0;
  int disposeCount = 0;

  @override
  void binds(Binder i) {}

  @override
  Future<void> onInit() async {
    initCount++;
  }

  @override
  void onDispose() {
    disposeCount++;
  }
}

Widget _buildHost({
  required bool showModule,
  required LifecycleModule module,
  required ModuleRetainer retainer,
  ModuleRetentionPolicy policy = ModuleRetentionPolicy.keepAlive,
}) {
  return ModularityRoot(
    retainer: retainer,
    child: MaterialApp(
      home: showModule
          ? ModuleScope(
              module: module,
              retentionPolicy: policy,
              child: const SizedBox.shrink(),
            )
          : const SizedBox.shrink(),
    ),
  );
}

void main() {
  group('KeepAlive retention', () {
    testWidgets('keeps module alive across widget remounts', (tester) async {
      final module = LifecycleModule();
      final retainer = ModuleRetainer();

      await tester.pumpWidget(
        _buildHost(showModule: true, module: module, retainer: retainer),
      );
      await tester.pumpAndSettle();

      expect(module.initCount, 1);
      expect(module.disposeCount, 0);
      expect(retainer.debugSnapshot().length, 1);

      await tester.pumpWidget(
        _buildHost(showModule: false, module: module, retainer: retainer),
      );
      await tester.pumpAndSettle();

      expect(module.disposeCount, 0,
          reason: 'Controller should stay cached, not disposed');

      await tester.pumpWidget(
        _buildHost(showModule: true, module: module, retainer: retainer),
      );
      await tester.pumpAndSettle();

      expect(module.initCount, 1,
          reason: 'Cached controller should be reused without re-init');
      expect(module.disposeCount, 0);
    });

    testWidgets('evict removes cached controller', (tester) async {
      final module = LifecycleModule();
      final retainer = ModuleRetainer();

      await tester.pumpWidget(
        _buildHost(showModule: true, module: module, retainer: retainer),
      );
      await tester.pumpAndSettle();

      final snapshot = retainer.debugSnapshot();
      expect(snapshot, hasLength(1));

      await tester.runAsync(() async {
        await retainer.evict(snapshot.first.key);
      });

      expect(module.disposeCount, 1);
    });
  });

  group('Strict retention', () {
    testWidgets('disposes controller on widget unmount', (tester) async {
      final module = LifecycleModule();
      final retainer = ModuleRetainer();

      await tester.pumpWidget(
        _buildHost(
          showModule: true,
          module: module,
          retainer: retainer,
          policy: ModuleRetentionPolicy.strict,
        ),
      );
      await tester.pumpAndSettle();

      expect(module.initCount, 1);

      await tester.pumpWidget(
        _buildHost(
          showModule: false,
          module: module,
          retainer: retainer,
          policy: ModuleRetentionPolicy.strict,
        ),
      );
      await tester.pumpAndSettle();

      expect(module.disposeCount, 1);
      expect(retainer.debugSnapshot(), isEmpty);
    });
  });
}
