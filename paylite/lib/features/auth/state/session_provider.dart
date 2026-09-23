import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paylite/core/security/secure_session_store.dart';

final sessionProvider = NotifierProvider<SessionNotifier, bool>(
  SessionNotifier.new,
);

class SessionNotifier extends Notifier<bool> {
  final _store = SecureSessionStore();

  @override
  bool build() {
    _restore();
    return false;
  }

  Future<void> _restore() async {
    final token = await _store.getAccessToken();
    if (token != null) state = true;
  }

  void signIn() => state = true;

  Future<void> signOut() async {
    await _store.clearAccessToken();
    state = false;
  }
}   