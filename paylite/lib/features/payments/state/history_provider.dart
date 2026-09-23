import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paylite/features/payments/domain/models/payment.dart';
import 'package:paylite/features/payments/state/payment_flow_provider.dart';

final historyProvider = AsyncNotifierProvider<HistoryNotifier, List<Payment>>(
  HistoryNotifier.new,
);

class HistoryNotifier extends AsyncNotifier<List<Payment>> {
  String _filter = 'all';
  String _query = '';
  String? _nextCursor;
  bool _loadingMore = false;

  bool get hasMore => _nextCursor != null;
  bool get isLoadingMore => _loadingMore;
  String get filter => _filter;
  String get query => _query;

  @override
  Future<List<Payment>> build() async {
    final page = await ref.read(paymentRepositoryProvider).getHistory();
    _nextCursor = page.nextCursor;
    return page.items;
  }

  Future<void> refresh({String? filter, String? query}) async {
    if (filter != null) _filter = filter;
    if (query != null) _query = query;
    _nextCursor = null;
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page = await ref.read(paymentRepositoryProvider).getHistory(
            filter: _filter,
            query: _query,
          );
      _nextCursor = page.nextCursor;
      return page.items;
    });
  }

  Future<void> loadMore() async {
    if (_loadingMore || _nextCursor == null || !state.hasValue) return;
    _loadingMore = true;
    try {
      final page = await ref.read(paymentRepositoryProvider).getHistory(
            cursor: _nextCursor,
            filter: _filter,
            query: _query,
          );
      _nextCursor = page.nextCursor;
      state = AsyncData([...state.requireValue, ...page.items]);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    } finally {
      _loadingMore = false;
    }
  }
}