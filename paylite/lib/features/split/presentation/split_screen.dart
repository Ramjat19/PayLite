import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:paylite/core/errors/bank_error.dart';
import 'package:paylite/core/utils/money.dart';
import 'package:paylite/features/collect/state/collect_provider.dart';

class SplitScreen extends ConsumerStatefulWidget {
  const SplitScreen({super.key});

  @override
  ConsumerState<SplitScreen> createState() => _SplitScreenState();
}

class _SplitScreenState extends ConsumerState<SplitScreen> {
  final _totalController = TextEditingController();
  final _participants = <_SplitEntry>[_SplitEntry(), _SplitEntry()];
  bool _equalSplit = true;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _totalController.dispose();
    for (final participant in _participants) {
      participant.dispose();
    }
    super.dispose();
  }

  int? get _totalPaise {
    final value = double.tryParse(_totalController.text.trim());
    return value == null || value <= 0 ? null : (value * 100).round();
  }

  int get _allocatedPaise => _participants.fold(
        0,
      (sum, participant) => sum + _parseRupees(participant.amount.text),
      );

  int get _difference => (_totalPaise ?? 0) - _allocatedPaise;

  void _applyEqualSplit() {
    final total = _totalPaise;
    if (total == null || _participants.isEmpty) return;
    final share = total ~/ _participants.length;
    final remainder = total % _participants.length;
    for (var index = 0; index < _participants.length; index++) {
      _participants[index].amount.text =
          ((share + (index == 0 ? remainder : 0)) / 100).toStringAsFixed(2);
    }
    setState(() {});
  }

  Future<void> _send() async {
    final total = _totalPaise;
    if (total == null || _difference != 0 || _participants.any((p) => p.vpa.text.trim().isEmpty)) {
      setState(() => _error = 'Enter valid participants and match the total exactly.');
      return;
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref.read(collectRequestsProvider.notifier).createSplitRequests(
            participants: _participants
                .map((participant) => (
                      vpa: participant.vpa.text.trim(),
                      amountPaise: _parseRupees(participant.amount.text),
                    ))
                .toList(),
          );
      if (mounted) context.go('/requests');
    } on BankError catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalPaise;
    return Scaffold(
      appBar: AppBar(title: const Text('Split bill')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _totalController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              if (_equalSplit) _applyEqualSplit();
              setState(() {});
            },
            decoration: const InputDecoration(
              labelText: 'Total bill',
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('Equal')),
              ButtonSegment(value: false, label: Text('Custom')),
            ],
            selected: {_equalSplit},
            onSelectionChanged: (selection) {
              setState(() => _equalSplit = selection.first);
              if (_equalSplit) _applyEqualSplit();
            },
          ),
          const SizedBox(height: 20),
          const Text('Participants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          for (var index = 0; index < _participants.length; index++)
            _ParticipantRow(
              entry: _participants[index],
              equalSplit: _equalSplit,
              onChanged: () => setState(() {}),
              onRemove: _participants.length > 2
                  ? () {
                      setState(() {
                        final removed = _participants.removeAt(index);
                        removed.dispose();
                        if (_equalSplit) _applyEqualSplit();
                      });
                    }
                  : null,
            ),
          TextButton.icon(
            onPressed: () {
              setState(() => _participants.add(_SplitEntry()));
              if (_equalSplit) _applyEqualSplit();
            },
            icon: const Icon(Icons.person_add),
            label: const Text('Add participant'),
          ),
          const SizedBox(height: 12),
          if (total != null)
            Text(
              _difference == 0
                  ? 'Total: ${formatMoney(total)}'
                  : 'Difference: ${formatMoney(_difference.abs())}',
              style: TextStyle(
                color: _difference == 0 ? Colors.green : Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _sending || total == null || _difference != 0
                ? null
                : _send,
            icon: _sending
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.send),
            label: const Text('Send requests'),
          ),
        ],
      ),
    );
  }
}

class _SplitEntry {
  final vpa = TextEditingController();
  final amount = TextEditingController();

  void dispose() {
    vpa.dispose();
    amount.dispose();
  }
}

class _ParticipantRow extends StatelessWidget {
  const _ParticipantRow({
    required this.entry,
    required this.equalSplit,
    required this.onChanged,
    required this.onRemove,
  });

  final _SplitEntry entry;
  final bool equalSplit;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: entry.vpa,
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                labelText: 'Participant UPI ID',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: TextField(
              controller: entry.amount,
              readOnly: equalSplit,
              onChanged: (_) => onChanged(),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '₹',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(onPressed: onRemove, icon: const Icon(Icons.close)),
        ],
      ),
    );
  }
}

int _parseRupees(String value) {
  final amount = double.tryParse(value.trim());
  return amount == null || amount < 0 ? 0 : (amount * 100).round();
}