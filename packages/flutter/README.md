# modularity_flutter

Flutter integration for the Modularity framework.

## Features

- **ModularityRoot**: InheritedWidget that holds the DI container factory and module registry.
- **ModuleScope**: Scopes dependencies to a specific part of the widget tree.
- **ModuleProvider**: Provides access to dependencies in the widget tree.
- **RouteObserver**: Automatically handles module lifecycle based on navigation.

## Usage

Wrap your application in `ModularityRoot`:

```dart
void main() {
  runApp(
    ModularityRoot(
      child: MyApp(),
    ),
  );
}
```

Use `ModuleScope` to define a module for a subtree:

```dart
class FeaturePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ModuleScope(
      module: FeatureModule(),
      child: FeatureView(),
    );
  }
}
```
