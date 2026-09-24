import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:paylite/core/utils/money.dart';
import 'package:paylite/features/payments/domain/models/payment.dart';
import 'package:paylite/features/home/state/account_provider.dart';

class ReceiptScreen extends ConsumerWidget {
  const ReceiptScreen({super.key, required this.payment});

  final Payment payment;

  String get _shareText {
    return 'PayLite receipt\n'
        'SUCCESS\n'
        '${formatMoney(payment.amountPaise)}\n'
        '${payment.counterparty.verifiedName}\n'
        '${payment.counterparty.address}\n'
        'Reference: ${payment.upiRef ?? 'Unavailable'}';
  }

  void _copyReference(BuildContext context) {
    final reference = payment.upiRef;
    if (reference == null || reference.isEmpty) return;
    Clipboard.setData(ClipboardData(text: reference));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reference copied')),
    );
  }

  Future<void> _share() => SharePlus.instance.share(ShareParams(text: _shareText));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reference = payment.upiRef;
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 72),
          const SizedBox(height: 16),
          const Center(
            child: Text('SUCCESS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(formatMoney(payment.amountPaise), style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 24),
          _ReceiptRow(label: 'To', value: payment.counterparty.verifiedName),
          _ReceiptRow(label: 'UPI ID', value: payment.counterparty.address),
          _ReceiptRow(label: 'Reference', value: reference ?? 'Unavailable'),
          _ReceiptRow(label: 'Date', value: _formatDate(payment.createdAt)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: reference == null ? null : () => _copyReference(context),
            icon: const Icon(Icons.copy),
            label: const Text('Copy reference'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _share,
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              ref.invalidate(accountProvider);
              ref.invalidate(recentPaymentsProvider);
              context.go('/home');
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime value) {
  final months = const ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${value.day} ${months[value.month - 1]} ${value.year}';
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label, style: TextStyle(color: Colors.grey.shade700))),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}