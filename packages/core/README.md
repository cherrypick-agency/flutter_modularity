# modularity_core

Core implementation of the Modularity framework, providing Dependency Injection (DI) container and Module Lifecycle management.

## Features

- **SimpleBinder**: A lightweight, platform-agnostic DI container.
- **Module Lifecycle**: Manage initialization and disposal of modules.
- **Scoped Injection**: Hierarchical injectors (parent/child scopes).
- **Modularity**: Clean separation of feature modules.

## Usage

```dart
import 'package:modularity_core/modularity_core.dart';

class MyModule extends Module {
  @override
  void binds(Binder binder) {
    binder.singleton(() => MyService());
  }
}

class MyService {
  void sayHello() => print('Hello!');
}

void main() {
  // Create a binder factory
  final factory = SimpleBinderFactory();
  
  // Create a generic binder
  final binder = factory.create();
  
  // Register module
  final module = MyModule();
  module.binds(binder);
  
  // Resolve dependency
  final service = binder.get<MyService>();
  service.sayHello();
}
```
