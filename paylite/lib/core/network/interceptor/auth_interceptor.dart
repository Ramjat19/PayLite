import 'package:dio/dio.dart';
import '../../security/secure_session_store.dart';

class AuthInterceptor extends Interceptor {
  final SecureSessionStore _store = SecureSessionStore();

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _store.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  // Called by your AuthRepository after login
  void onAuth(String accessToken) {
    _store.saveAccessToken(accessToken);
  }

  void onLogout() {
    _store.clearAccessToken();
  }
}   