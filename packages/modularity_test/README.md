# modularity_test

Testing utilities for the Modularity framework.

## Features

- **testModule**: Helper to unit test modules with a mocked/real binder.
- **TestBinder**: Wrapper around Binder to assert registrations and calls.

## Usage

```dart
import 'package:modularity_test/modularity_test.dart';
import 'package:test/test.dart';

void main() {
  test('verify module registrations', () async {
    await testModule(
      MyModule(),
      (module, binder) async {
        // Verify service registration
        final service = binder.get<MyService>();
        expect(service, isNotNull);
      },
    );
  });
}
```
