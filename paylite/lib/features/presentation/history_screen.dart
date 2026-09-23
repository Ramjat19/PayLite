import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paylite/core/utils/money.dart';
import 'package:paylite/features/payments/domain/models/payment.dart';
import 'package:paylite/features/payments/state/history_provider.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 300) {
      ref.read(historyProvider.notifier).loadMore();
    }
  }

  void _search(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(historyProvider.notifier).refresh(query: value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    final notifier = ref.read(historyProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: const InputDecoration(
                labelText: 'Search name or UPI ID',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                for (final option in const [
                  ('all', 'All'),
                  ('sent', 'Sent'),
                  ('received', 'Received'),
                  ('failed', 'Failed'),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(option.$2),
                      selected: notifier.filter == option.$1,
                      onSelected: (_) => notifier.refresh(filter: option.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => notifier.refresh(),
              child: history.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => ListView(
                  children: [
                    const SizedBox(height: 180),
                    Center(child: Text('$error')),
                  ],
                ),
                data: (payments) => payments.isEmpty
                    ? ListView(
                        children: const [
                          SizedBox(height: 180),
                          Center(child: Text('No payments found')),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 24),
                        itemCount: payments.length + (notifier.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == payments.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }
                          return _HistoryTile(payment: payments[index]);
                        },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.payment});

  final Payment payment;

  @override
  Widget build(BuildContext context) {
    final received = payment.direction == PaymentDirection.received;
    final failed = payment.status == PaymentStatus.failed;
    final color = failed
        ? Colors.red
        : received
            ? Colors.green
            : Colors.black87;
    final prefix = received ? '+' : '-';

    return ListTile(
      leading: CircleAvatar(child: Text(payment.counterparty.verifiedName[0])),
      title: Text(payment.counterparty.verifiedName),
      subtitle: Text(payment.status.name.toUpperCase()),
      trailing: Text(
        '$prefix${formatMoney(payment.amountPaise)}',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}