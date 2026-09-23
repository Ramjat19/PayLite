import 'package:dio/dio.dart';
import 'package:paylite/core/network/api_client.dart';
import 'package:paylite/core/errors/bank_error.dart';
import 'package:paylite/features/accounts/domain/models/account.dart';
import 'package:paylite/features/payments/domain/models/payment.dart';

class AccountRepository {
  final Dio _dio = ApiClient().dio;

  Future<Account> getPrimaryAccount() async {
    try {
      final res = await _dio.get('/accounts/primary');
      return Account.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error as BankError;
    }
  }

  Future<List<Payment>> getRecentPayments() async {
    try {
      final res = await _dio.get('/payments');
      final data = (res.data as Map).cast<String, Object?>();
      final items = data['items'] as List<Object?>;
      return items
          .map((item) => Payment.fromJson(
                (item as Map).cast<String, Object?>(),
              ))
          .toList();
    } on DioException catch (e) {
      throw e.error as BankError;
    }
  }
}   