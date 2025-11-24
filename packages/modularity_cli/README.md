# modularity_cli

Visualization tools for the Modularity framework.

## Features

- **GraphVisualizer**: Generate Graphviz (DOT) representation of your module tree and open it in the browser.

## Usage

```dart
import 'package:modularity_cli/modularity_cli.dart';

void main() async {
  final rootModule = AppModule();
  
  // Generate and open graph in browser
  await GraphVisualizer.visualize(rootModule);
}
```
