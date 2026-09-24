import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paylite/features/accounts/domain/models/account.dart';
import 'package:paylite/features/home/data/account_repository.dart';
import 'package:paylite/features/payments/domain/models/payment.dart';

final accountRepositoryProvider = Provider((ref) => AccountRepository());

final accountProvider = AsyncNotifierProvider<AccountNotifier, Account>(
  AccountNotifier.new,
);

class AccountNotifier extends AsyncNotifier<Account> {
  @override
  Future<Account> build() async {
    return ref.watch(accountRepositoryProvider).getPrimaryAccount();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(accountRepositoryProvider).getPrimaryAccount(),
    );
  }
}

final recentPaymentsProvider = FutureProvider<List<Payment>>((ref) {
  return ref.watch(accountRepositoryProvider).getRecentPayments();
});   