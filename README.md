# Modularity Framework

![coverage](https://img.shields.io/badge/coverage-61.4%25-yellow)

![screenshot](image.png)

A modular architecture framework for Flutter applications based on Clean Architecture & SOLID principles. Designed for enterprise-scale apps requiring strict isolation, testability, and a predictable lifecycle.

## 📦 Packages

- **[contracts](packages/contracts)**: Zero-dependency interfaces.
- **[core](packages/core)**: DI container and state machine logic.
- **[flutter](packages/flutter)**: Flutter widgets and `RouteObserver` integration.
- **[modularity_test](packages/modularity_test)**: Unit testing utilities (`testModule`).
- **[modularity_cli](packages/modularity_cli)**: Graph visualization tools.

## 🚀 Key Features

- **Strict Dependency Injection**: Dependencies are explicitly `imported` and `exported`. No hidden global access.
- **Deterministic Lifecycle**: Modules pass through a formal state machine (`initial` → `loading` → `loaded` → `disposed`). `onInit` runs only after all imports are ready.
- **Retention Policies**: Control module lifetime (`RouteBound`, `KeepAlive`, `Strict`).
- **Framework Agnostic**: Works with GoRouter, AutoRoute, or Navigator 1.0.
- **Observability**: Built-in interceptors and Graphviz visualization support.

## ⚖️ Comparison

How **Modularity** compares to other popular approaches in the Flutter ecosystem:

| Feature | Modularity (This Framework) | Flutter Modular | Provider / Riverpod / BLoC |
| :--- | :--- | :--- | :--- |
| **Module Definition** | **Pure Dart class + State Machine**. Encapsulated logic decoupled from UI. | **Class with routes & binds**. Strongly coupled to the router and UI navigation. | **Folder structure / Providers list**. No formal module concept; usually just a list of global or scoped providers. |
| **Initialization** | **Automatic (DAG)**. `onInit` is guaranteed to run after all imports are resolved and initialized. Solves "Initialization Hell". | **Lazy or Navigation-based**. initialization happens when the route is accessed or the bind is called. | **Lazy or Widget-mount**. Initialization happens when the widget tree is built or the provider is first read. |
| **Dependency Management** | **Explicit**. Uses `imports`, `exports`, and `binds`. Modules cannot access what they don't strictly import. | **Module Tree / Global**. Hierarchical scoping, but often allows accessing parent scopes implicitly. | **Global / Scoped**. `ProviderScope` or `MultiBlocProvider` in the widget tree. Dependencies often implicit via `context.read`. |
| **Lifecycle** | **Formal State Machine**. Strict states (`initial`, `loading`, `loaded`, `disposed`) managed by the core engine. | **Bound to Router**. Lifecycle is tied to Modular's internal router and navigation stack. | **Bound to Widget Tree**. Lifecycle is tied to the `BuildContext` (StatefulWidget) or Provider's auto-dispose logic. |
| **Routing Coupling** | **Loose**. Works with any router (GoRouter, AutoRoute, etc.). Routing is an implementation detail. | **Strong**. The router is a core part of the framework. Hard to use with other routing solutions. | **Indirect**. No direct coupling, but state management often gets entangled with navigation arguments. |
| **Testing** | **Unit-first**. `testModule` isolates logic completely. You can test the entire wiring without Flutter. | **Integration mainly**. Focuses on testing the module with the router mocked or real. | **Widget tests required**. Often requires `pumpWidget` to test the DI integration properly. |

## 🛠 Getting Started

### 1. Define a Module

```dart
import 'package:modularity_contracts/modularity_contracts.dart';

class AppModule extends Module {
  @override
  List<Module> get imports => [ /* SharedModule() */ ];

  @override
  void binds(Binder i) {
    // Private: Implementation details
    i.singleton<AuthRepository>(() => AuthRepositoryImpl());
  }

  @override
  void exports(Binder i) {
    // Public: Exposed API
    i.singleton<AuthService>(() => AuthService(i.get()));
  }
  
  @override
  Future<void> onInit() async {
    // Safe to use imports here - they are guaranteed to be ready
    await i.get<AuthService>().initialize();
  }
}
```

### 2. Initialize Root

```dart
void main() {
  runApp(ModularityRoot(
    child: MaterialApp(
      home: ModuleScope(
        module: AppModule(),
        child: HomePage(),
      ),
    ),
  ));
}
```

### 3. Use in UI

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Type-safe dependency resolution
    final authService = ModuleProvider.of(context).get<AuthService>();
    
    return Text('Logged in: ${authService.isLoggedIn}');
  }
}
```

## 🧪 Testing

Use `modularity_test` to verify your module's wiring and logic in isolation.

```dart
import 'package:modularity_test/modularity_test.dart';

void main() {
  test('AppModule registers AuthService', () async {
    await testModule(AppModule(), (module, binder) {
      expect(binder.get<AuthService>(), isNotNull);
      expect(binder.get<AuthService>().isLoggedIn, isFalse);
    });
  });
}
```
