import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paylite/features/vpa/data/vpa_repository.dart';
import 'package:paylite/features/vpa/domain/models/vpa.dart';
import 'package:paylite/features/scan/data/qr_parser.dart';
// import 'package:paylite/features/auth/state/session_provider.dart';

final vpaRepositoryProvider = Provider((ref) => VpaRepository());

// Holds the parsed QR data passed from ScanScreen
final parsedQrProvider = NotifierProvider<ParsedQrNotifier, ParsedQr?>(
  ParsedQrNotifier.new,
);

class ParsedQrNotifier extends Notifier<ParsedQr?> {
  @override
  ParsedQr? build() => null;

  void set(ParsedQr value) => state = value;
}

final vpaLookupProvider = AsyncNotifierProvider<VpaLookupNotifier, Vpa>(
  VpaLookupNotifier.new,
);

class VpaLookupNotifier extends AsyncNotifier<Vpa> {
  @override
  Future<Vpa> build() async {
    final parsed = ref.watch(parsedQrProvider);
    if (parsed == null) {
      throw Exception('No QR data');
    }
    return ref.watch(vpaRepositoryProvider).lookup(parsed.vpa);
  }
}   