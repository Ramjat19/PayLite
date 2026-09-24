import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import 'package:paylite/features/accounts/domain/models/account.dart';
import 'session_provider.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authProvider = AsyncNotifierProvider<AuthNotifier, Account>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<Account> {
  @override
  Future<Account> build() async {
    // Stay pending until login() is called
    return Completer<Account>().future;
  }

  Future<void> login({
    required String customerId,
    required String pin,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(authRepositoryProvider);
      final account = await repo.login(customerId: customerId, pin: pin);
      ref.read(sessionProvider.notifier).signIn();
      return account;
    });
  }
}   