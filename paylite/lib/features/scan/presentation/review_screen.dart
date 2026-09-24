import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paylite/core/utils/money.dart';
import 'package:paylite/features/payments/state/payment_flow_provider.dart';
import 'package:uuid/uuid.dart';

class ReviewScreen extends ConsumerWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final extra = GoRouterState.of(context).extra;
    if (extra is! Map) return const _InvalidPaymentData();

    final data = Map<String, dynamic>.from(extra);
    final name = data['name'] as String?;
    final vpa = data['vpa'] as String?;
    final amountPaise = data['amountPaise'] as int?;
    final note = data['note'] as String? ?? '';
    if (name == null || vpa == null || amountPaise == null) {
      return const _InvalidPaymentData();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Review payment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 24),
            _Row(label: 'To', value: name),
            _Row(label: 'VPA', value: vpa),
            _Row(label: 'Amount', value: formatMoney(amountPaise)),
            if (note.isNotEmpty) _Row(label: 'Note', value: note),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final key = data['idempotencyKey'] as String? ??
                      const Uuid().v4();
                  data['idempotencyKey'] = key;
                  ref.read(paymentFlowProvider.notifier).preparePayment(key);
                  context.goNamed('payPin', extra: data);
                },
                child: const Text('Enter PIN'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvalidPaymentData extends StatelessWidget {
  const _InvalidPaymentData();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: const Center(child: Text('Payment details are missing.')),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}   