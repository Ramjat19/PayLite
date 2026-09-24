import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// import 'package:paylite/core/utils/money.dart';
import 'package:paylite/features/scan/data/qr_parser.dart';
import 'package:paylite/features/vpa/state/vpa_lookup_provider.dart';

class PayScreen extends ConsumerWidget {
  const PayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final parsed = ref.watch(parsedQrProvider);
    if (parsed == null) return const _ManualPayForm();

    final vpaState = ref.watch(vpaLookupProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pay')),
      body: vpaState.when(
        data: (vpa) {
          // VPA verified → show pay form
          return _PayForm(parsed: parsed, vpa: vpa);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          // VPA not found or other error
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('$e', textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Go Home'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ManualPayForm extends StatefulWidget {
  const _ManualPayForm();

  @override
  State<_ManualPayForm> createState() => _ManualPayFormState();
}

class _ManualPayFormState extends State<_ManualPayForm> {
  final _vpaController = TextEditingController();
  final _amountController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _vpaController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _continue() {
    final vpa = _vpaController.text.trim().toLowerCase();
    final amount = double.tryParse(_amountController.text.trim());
    if (!vpa.contains('@') || amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid UPI ID and amount.');
      return;
    }
    context.goNamed('payReview', extra: {
      'vpa': vpa,
      'name': vpa,
      'amountPaise': (amount * 100).round(),
      'note': '',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pay')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Pay with UPI ID', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Scan a QR code to fill this automatically, or enter the details manually.'),
          const SizedBox(height: 24),
          TextField(
            controller: _vpaController,
            decoration: const InputDecoration(
              labelText: 'Recipient UPI ID',
              hintText: 'merchant@paylite',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _continue,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continue'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/scan'),
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan QR instead'),
          ),
        ],
      ),
    );
  }
}

class _PayForm extends ConsumerStatefulWidget {
  final ParsedQr parsed;
  final dynamic vpa;
  const _PayForm({required this.parsed, required this.vpa});

  @override
  ConsumerState<_PayForm> createState() => _PayFormState();
}

class _PayFormState extends ConsumerState<_PayForm> {
  late final TextEditingController _amountCtrl;
  late final TextEditingController _noteCtrl;
  late final bool _amountLocked;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: widget.parsed.amountPaise > 0
          ? '${(widget.parsed.amountPaise / 100).toStringAsFixed(2)}'
          : '',
    );
    _amountLocked = widget.parsed.amountPaise > 0;
    _noteCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  void _proceed() {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount <= 0) return;
    context.goNamed('payReview', extra: {
      'vpa': widget.parsed.vpa,
      'name': widget.parsed.name,
      'amountPaise': (amount * 100).round(),
      'note': _noteCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipient info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(widget.parsed.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(widget.parsed.vpa,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Amount
          TextField(
            controller: _amountCtrl,
            keyboardType: TextInputType.number,
            readOnly: _amountLocked,
            decoration: const InputDecoration(
              labelText: 'Amount (₹)',
              prefixIcon: Icon(Icons.currency_rupee),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          // Note
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _proceed,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}   