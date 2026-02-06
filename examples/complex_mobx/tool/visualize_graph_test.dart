import 'package:complex_mobx/src/modules/root/root_module.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:modularity_cli/modularity_cli.dart';

void main() {
  test('Generate Dependency Graph', () async {
    print('Generating dependency graph for RootModule (complex_mobx)...');
    await GraphVisualizer.visualize(RootModule());
  });
}
