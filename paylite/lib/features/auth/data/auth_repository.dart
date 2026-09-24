import 'package:dio/dio.dart';
import 'package:paylite/core/network/api_client.dart';
import 'package:paylite/core/errors/bank_error.dart';
import 'package:paylite/core/errors/error_mapper.dart';
import 'package:paylite/core/security/secure_session_store.dart';
import 'package:paylite/features/accounts/domain/models/account.dart';
import 'package:paylite/features/auth/domain/models/auth_session.dart';

class AuthRepository {
  final Dio _dio = ApiClient().dio;
  final SecureSessionStore _sessionStore = SecureSessionStore();

  Future<Account> login({
    required String customerId,
    required String pin,
  }) async {
    try {
      final res = await _dio.post(
        '/auth/login',
        data: {'customerId': customerId, 'pin': pin},
      );

      final session = AuthSession.fromJson(
        (res.data as Map).cast<String, Object?>(),
      );
      await _sessionStore.saveAccessToken(session.token);

      final accountRes = await _dio.get('/accounts/primary');
      return Account.fromJson(
        (accountRes.data as Map).cast<String, Object?>(),
      );
    } on DioException catch (e) {
      throw e.error is BankError ? e.error! : ErrorMapper.map(e);
    }
  }
}   