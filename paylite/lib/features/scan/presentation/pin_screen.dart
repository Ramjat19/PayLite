import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paylite/core/errors/bank_error.dart';
import 'package:paylite/core/utils/money.dart';
// import 'package:paylite/features/payments/data/payment_repository.dart';
import 'package:paylite/features/payments/state/payment_flow_provider.dart';

class PinScreen extends ConsumerWidget {
  const PinScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(paymentFlowProvider, (previous, next) {
      final payment = next.value;
      if (payment != null && previous?.value?.id != payment.id) {
        context.go('/pay/status/${payment.id}');
      }
    });

    final extra = GoRouterState.of(context).extra;
    if (extra is! Map) return const _InvalidPaymentData();

    final data = Map<String, dynamic>.from(extra);
    final amountPaise = data['amountPaise'] as int?;
    final vpa = data['vpa'] as String?;
    final note = data['note'] as String? ?? '';
    final idempotencyKey = data['idempotencyKey'] as String?;
    if (amountPaise == null || vpa == null || idempotencyKey == null) {
      return const _InvalidPaymentData();
    }

    final flowState = ref.watch(paymentFlowProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Enter PIN')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Paying ${formatMoney(amountPaise)}',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            // Simple PIN input (4 digits)
            _PinPad(onComplete: (pin) {
              ref.read(paymentFlowProvider.notifier).submit(
                pin: pin,
                vpa: vpa,
                amountPaise: amountPaise,
                note: note,
              );
            }),
            if (flowState.hasError) ...[
              const SizedBox(height: 16),
              Text(
                flowState.error is BankError
                  ? (flowState.error! as BankError).message
                  : 'Unable to complete payment. Please try again.',
                  style: const TextStyle(color: Colors.red)),
            ],
            if (flowState.isLoading) ...[
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
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
      appBar: AppBar(title: const Text('Enter PIN')),
      body: const Center(child: Text('Payment details are missing.')),
    );
  }
}

class _PinPad extends StatefulWidget {
  final void Function(String pin) onComplete;
  const _PinPad({required this.onComplete});

  @override
  State<_PinPad> createState() => _PinPadState();
}

class _PinPadState extends State<_PinPad> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: _ctrl,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 4,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 32, letterSpacing: 8),
        decoration: const InputDecoration(
          counterText: '',
          border: OutlineInputBorder(),
        ),
        onChanged: (v) {
          if (v.length == 4) {
            widget.onComplete(v);
          }
        },
      ),
    );
  }
}   