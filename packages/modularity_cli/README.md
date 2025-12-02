# modularity_cli

Visualization tools for the Modularity framework.

## Features

- **GraphVisualizer**: Generate visual dependency graphs of your module tree
- **Multiple renderers**: Choose between static Graphviz or interactive AntV G6
- **Public/Private bindings**: See which dependencies are exported vs internal
- **Dependency types**: Visualize singleton, factory, and instance registrations

## Usage

### Basic (Graphviz - static)

```dart
import 'package:modularity_cli/modularity_cli.dart';

void main() async {
  final rootModule = AppModule();
  
  // Static Graphviz diagram (default)
  await GraphVisualizer.visualize(rootModule);
}
```

### Interactive (AntV G6)

```dart
import 'package:modularity_cli/modularity_cli.dart';

void main() async {
  final rootModule = AppModule();
  
  // Interactive diagram with drag, zoom, and tooltips
  await GraphVisualizer.visualize(
    rootModule,
    renderer: GraphRenderer.g6,
  );
}
```

## Renderers

| Renderer | Description |
|----------|-------------|
| `GraphRenderer.graphviz` | Static DOT diagram via quickchart.io. Best for documentation and quick overview. |
| `GraphRenderer.g6` | Interactive AntV G6 diagram. Drag nodes, zoom, hover for dependency details. |

## What's Visualized

- **Modules**: Each module is a node showing its name
- **Imports**: Dashed arrows showing module dependencies
- **Submodules**: Solid arrows with diamond showing composition
- **Public exports**: Dependencies registered in `exports()` method
- **Private bindings**: Dependencies registered in `binds()` method
- **Registration type**: singleton, factory, or instance
