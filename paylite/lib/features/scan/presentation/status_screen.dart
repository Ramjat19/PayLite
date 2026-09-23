import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paylite/core/utils/money.dart';
import 'package:paylite/core/errors/bank_error.dart';
import 'package:paylite/features/payments/state/payment_status_provider.dart';
import 'package:paylite/features/payments/domain/models/payment.dart';

class StatusScreen extends ConsumerWidget {
  final String id;
  const StatusScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusState = ref.watch(paymentStatusProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Status')),
      body: statusState.when(
        data: (payment) => _PaymentStatusBody(payment: payment),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 72, color: Colors.red),
              const SizedBox(height: 16),
              Text(e is BankError ? e.message : 'Unable to retrieve payment status.'),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/home'),
                child: const Text('Go Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}   

class _PaymentStatusBody extends StatelessWidget {
  final Payment payment;

  const _PaymentStatusBody({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isPending = payment.status == PaymentStatus.pending;
    final isFailed = payment.status == PaymentStatus.failed;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPending ? Icons.hourglass_top : isFailed ? Icons.error : Icons.check_circle,
            size: 72,
            color: isPending ? Colors.orange : isFailed ? Colors.red : Colors.green,
          ),
          const SizedBox(height: 16),
          Text(
            isPending
                ? 'Pending - we will notify you'
                : isFailed
                    ? 'Payment failed'
                    : 'Payment successful',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(formatMoney(payment.amountPaise), style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.go('/home'),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}