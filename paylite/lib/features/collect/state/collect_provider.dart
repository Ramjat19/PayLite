import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paylite/features/collect/data/collect_repository.dart';
import 'package:paylite/features/collect/domain/models/collect_request.dart';

final collectRepositoryProvider = Provider((ref) => CollectRepository());

final collectRequestsProvider =
    AsyncNotifierProvider<CollectRequestsNotifier, List<CollectRequest>>(
  CollectRequestsNotifier.new,
);

class CollectRequestsNotifier extends AsyncNotifier<List<CollectRequest>> {
  @override
  Future<List<CollectRequest>> build() =>
      ref.read(collectRepositoryProvider).getAll();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(collectRepositoryProvider).getAll(),
    );
  }

  Future<void> createRequest({
    required String vpa,
    required int amountPaise,
  }) async {
    await ref.read(collectRepositoryProvider).create(
          vpa: vpa,
          amountPaise: amountPaise,
        );
    await refresh();
  }

  Future<void> createSplitRequests({
    required List<({String vpa, int amountPaise})> participants,
  }) async {
    for (final participant in participants) {
      await ref.read(collectRepositoryProvider).create(
            vpa: participant.vpa,
            amountPaise: participant.amountPaise,
          );
    }
    await refresh();
  }

  Future<void> decline(CollectRequest request) async {
    await ref.read(collectRepositoryProvider).decline(request.id);
    ref.invalidateSelf();
  }

  Future<void> pay(CollectRequest request, String pin) async {
    await ref.read(collectRepositoryProvider).pay(request: request, pin: pin);
    ref.invalidateSelf();
  }
}