import 'package:flutter_riverpod/flutter_riverpod.dart';

// Standard Riverpod Providers
final counterProvider = StateProvider<int>((ref) => 0);

class AuthService {
  AuthService(this.token);
  final String token;
}

// Provider needing external dependency
final authServiceProvider = Provider<AuthService>((ref) {
  throw UnimplementedError('Override this in ModuleScope');
});
