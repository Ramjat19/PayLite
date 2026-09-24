import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paylite/features/payments/data/payment_repository.dart';
import 'package:paylite/features/payments/domain/models/payment.dart';

final paymentRepositoryProvider = Provider((ref) => PaymentRepository());

final paymentFlowProvider =
    AsyncNotifierProvider<PaymentFlowNotifier, Payment?>(
  PaymentFlowNotifier.new,
);

class PaymentFlowNotifier extends AsyncNotifier<Payment?> {
  String? _idempotencyKey;

  String? get idempotencyKey => _idempotencyKey;

  @override
  Future<Payment?> build() async => null;

  void preparePayment(String idempotencyKey) {
    _idempotencyKey = idempotencyKey;
    state = const AsyncData(null);
  }

  Future<void> submit({
    required String pin,
    required String vpa,
    required int amountPaise,
    required String note,
  }) async {
    final idempotencyKey = _idempotencyKey;
    if (idempotencyKey == null) {
      state = AsyncError(
        StateError('Payment confirmation has expired. Please start again.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final payment = await ref.read(paymentRepositoryProvider).create(
        vpa: vpa,
        amountPaise: amountPaise,
        pin: pin,
        idempotencyKey: idempotencyKey,
        note: note,
      );
      return payment;
    });
  }
}   