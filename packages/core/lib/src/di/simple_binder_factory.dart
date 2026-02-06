import 'package:modularity_contracts/modularity_contracts.dart';
import 'simple_binder.dart';

/// Default [BinderFactory] that produces [SimpleBinder] instances.
class SimpleBinderFactory implements BinderFactory {
  /// Create a new [SimpleBinder], optionally chaining it to a [parent] scope.
  @override
  Binder create([Binder? parent]) {
    return SimpleBinder(parent: parent);
  }
}
