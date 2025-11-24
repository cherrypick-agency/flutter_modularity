import 'package:modularity_cli/modularity_cli.dart';
import 'package:modularity_contracts/modularity_contracts.dart';

class MyRootModule extends Module {
  @override
  void binds(Binder binder) {}
}

void main() async {
  print('Generating graph for MyRootModule...');
  try {
    await GraphVisualizer.visualize(MyRootModule());
    print('Graph generated successfully.');
  } catch (e) {
    print('Error generating graph: $e');
  }
}
