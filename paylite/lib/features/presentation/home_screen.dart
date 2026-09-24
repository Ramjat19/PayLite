import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paylite/core/utils/money.dart';
import 'package:paylite/features/accounts/domain/models/account.dart';
import 'package:paylite/features/payments/domain/models/payment.dart';
import 'package:paylite/features/home/state/account_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _hideBalance = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(accountProvider);
      ref.invalidate(recentPaymentsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accountState = ref.watch(accountProvider);
    final paymentsState = ref.watch(recentPaymentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('PayLite'),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.go('/notifications'),
            icon: const Icon(Icons.notifications_none),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(accountProvider.notifier).refresh();
          ref.invalidate(recentPaymentsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Balance card
            AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 280),
              child: accountState.when(
                data: (account) => _BalanceCard(
                  key: const ValueKey('balance-data'),
                  account: account,
                  hidden: _hideBalance,
                  onToggle: () => setState(() => _hideBalance = !_hideBalance),
                ),
                loading: () => const _BalanceSkeleton(key: ValueKey('balance-loading')),
                error: (e, _) => _RetryMessage(
                  key: const ValueKey('balance-error'),
                  message: 'Couldn\'t load your account.',
                  onRetry: () => ref.invalidate(accountProvider),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ActionButton(icon: Icons.qr_code_scanner, label: 'Scan',
                    onTap: () => context.go('/scan')),
                _ActionButton(icon: Icons.send, label: 'Pay',
                    onTap: () => context.go('/pay')),
                _ActionButton(icon: Icons.request_quote, label: 'Request',
                    onTap: () => context.go('/requests')),
              ],
            ),
            const SizedBox(height: 16),

            // Split
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.go('/split'),
                icon: const Icon(Icons.group),
                label: const Text('Split'),
              ),
            ),
            const SizedBox(height: 24),

            // Recent payments
            const Text('Recent payments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.go('/history'),
                icon: const Icon(Icons.history),
                label: const Text('View all'),
              ),
            ),
            paymentsState.when(
              data: (payments) => payments.isEmpty
                  ? const Text('No recent payments',
                      style: TextStyle(color: Colors.grey))
                  : Column(
                      children: payments
                          .map((p) => _PaymentTile(payment: p))
                          .toList(),
                    ),
              loading: () => const SizedBox(
                  height: 40,
                  child:
                      Center(child: CircularProgressIndicator(strokeWidth: 2))),
              error: (e, _) => _RetryMessage(
                message: 'Couldn\'t load recent payments.',
                onRetry: () => ref.invalidate(recentPaymentsProvider),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final Account account;
  final bool hidden;
  final VoidCallback onToggle;

  const _BalanceCard({
    super.key,
    required this.account,
    required this.hidden,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Balance',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                hidden ? '₹ ******' : formatMoney(account.balancePaise),
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          IconButton(
            tooltip: hidden ? 'Show balance' : 'Hide balance',
            icon: Icon(hidden ? Icons.visibility : Icons.visibility_off,
                color: Colors.white70),
            onPressed: onToggle,
          ),
        ],
      ),
    );
  }
}

class _RetryMessage extends StatelessWidget {
  const _RetryMessage({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(message),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
  }
}

class _BalanceSkeleton extends StatelessWidget {
  const _BalanceSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 60, height: 14, child: _Shimmer()),
              SizedBox(width: 120, height: 28, child: _Shimmer()),
            ],
          ),
          SizedBox(width: 24, height: 24, child: _Shimmer()),
        ],
      ),
    );
  }
}

class _Shimmer extends StatelessWidget {
  const _Shimmer();

  @override
  Widget build(BuildContext context) =>
      Container(decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(4)));
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final Payment payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final isCredit = payment.direction == PaymentDirection.received;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        backgroundColor: isCredit ? Colors.green.shade100 : Colors.red.shade100,
        child: Text(payment.counterparty.verifiedName[0].toUpperCase(),
            style: TextStyle(color: isCredit ? Colors.green.shade700 : Colors.red.shade700)),
      ),
      title: Text(payment.counterparty.verifiedName),
      trailing: Text(
        isCredit ? '+${formatMoney(payment.amountPaise)}' : '-${formatMoney(payment.amountPaise)}',
        style: TextStyle(
          color: isCredit ? Colors.green.shade700 : Colors.red.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}   