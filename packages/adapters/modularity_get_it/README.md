# modularity_get_it

GetIt adapter for the Modularity framework. Allows using [GetIt](https://pub.dev/packages/get_it) as the backing DI container.

## Features

- **GetItBinder**: Implementation of `Binder` that delegates to GetIt.
- **GetItBinderFactory**: Factory to create GetIt binders.
- **Scoped & Global**: Supports both new GetIt instances per scope or sharing the global instance.

## Usage

```dart
import 'package:modularity_core/modularity_core.dart';
import 'package:modularity_get_it/modularity_get_it.dart';

void main() {
  // Use GetIt as the DI container
  final factory = GetItBinderFactory();
  
  final binder = factory.create();
  final module = MyModule();
  
  module.binds(binder);
}
```
