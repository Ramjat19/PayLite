import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paylite/core/errors/bank_error.dart';
import 'package:paylite/core/utils/money.dart';
import 'package:paylite/features/collect/domain/models/collect_request.dart';
import 'package:paylite/features/collect/state/collect_provider.dart';
import 'package:paylite/features/home/state/account_provider.dart';

class RequestsScreen extends ConsumerWidget {
  const RequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(collectRequestsProvider);
    final account = ref.watch(accountProvider);
    final primaryVpa = account.hasValue ? account.value?.primaryVpa : null;
    return Scaffold(
      appBar: AppBar(title: const Text('Requests')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateRequestDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Request money'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(collectRequestsProvider.notifier).refresh(),
        child: requests.when(
          loading: () => ListView(
            children: [
              SizedBox(height: 240),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => ListView(
            children: [
              const SizedBox(height: 180),
              Center(child: Text('$error')),
            ],
          ),
          data: (items) => items.isEmpty
              ? ListView(
                  children: [
                    SizedBox(height: 180),
                    Center(child: Text('No requests')),
                  ],
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text('Incoming', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ...items.where((item) => item.to.address == primaryVpa).map(
                      (item) => _RequestTile(request: item, incoming: true),
                    ),
                    const SizedBox(height: 24),
                    const Text('Outgoing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    ...items.where((item) => item.from.address == primaryVpa).map(
                      (item) => _RequestTile(request: item, incoming: false),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _showCreateRequestDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final vpaController = TextEditingController();
    final amountController = TextEditingController();
    String? errorMessage;

    final result = await showDialog<(String, int)?>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Request money'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: vpaController,
                decoration: const InputDecoration(
                  labelText: 'Payer UPI ID',
                  hintText: 'ramesh@paylite',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '₹ ',
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text.trim());
                if (vpaController.text.trim().isEmpty || amount == null || amount <= 0) {
                  setDialogState(() => errorMessage = 'Enter a valid UPI ID and amount.');
                  return;
                }
                Navigator.pop(dialogContext, (
                  vpaController.text.trim(),
                  (amount * 100).round(),
                ));
              },
              child: const Text('Send request'),
            ),
          ],
        ),
      ),
    );
    vpaController.dispose();
    amountController.dispose();

    if (result == null || !context.mounted) return;
    try {
      await ref.read(collectRequestsProvider.notifier).createRequest(
            vpa: result.$1,
            amountPaise: result.$2,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent')),
        );
      }
    } on BankError catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    }
  }
}

class _RequestTile extends ConsumerWidget {
  const _RequestTile({required this.request, required this.incoming});

  final CollectRequest request;
  final bool incoming;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expired = request.isExpired;
    final pending = request.status == CollectRequestStatus.pending && !expired;
    final other = incoming ? request.from : request.to;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              incoming
                  ? '${other.verifiedName} requests ${formatMoney(request.amountPaise)}'
                  : 'Request to ${other.verifiedName} ${formatMoney(request.amountPaise)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Text(expired ? 'This request has expired.' : request.status.name.toUpperCase()),
            if (incoming && pending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(
                    onPressed: () => _showPinDialog(context, ref),
                    child: const Text('Pay'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => ref.read(collectRequestsProvider.notifier).decline(request),
                    child: const Text('Decline'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showPinDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final pin = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter payment PIN'),
        content: TextField(
          controller: controller,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 4,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Pay'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (pin != null && pin.length == 4) {
      await ref.read(collectRequestsProvider.notifier).pay(request, pin);
    }
  }
}