import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:paylite/core/network/api_client.dart';
import 'package:paylite/core/errors/bank_error.dart';
import 'package:paylite/features/payments/domain/models/payment.dart';

class PaymentRepository {
  final Dio _dio = ApiClient().dio;

  Future<Payment> create({
    required String vpa,
    required int amountPaise,
    required String pin,
    required String idempotencyKey,
    String note = '',
  }) async {
    try {
      final res = await _dio.post('/payments', data: {
        'vpa': vpa,
        'amountPaise': amountPaise,
        'upiPinHash': sha256.convert(utf8.encode(pin)).toString(),
        'note': note,
      }, options: Options(headers: {
        'Idempotency-Key': idempotencyKey,
      }));
      final data = (res.data as Map).cast<String, Object?>();
      final paymentData = data['payment'] ?? data;
      return Payment.fromJson(
        (paymentData as Map).cast<String, Object?>(),
      );
    } on DioException catch (e) {
      throw e.error as BankError;
    }
  }

  Future<Payment> getStatus(String id) async {
    try {
      final res = await _dio.get('/payments/$id');
      return Payment.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error as BankError;
    }
  }

  Future<PaymentPage> getHistory({
    String? cursor,
    String? filter,
    String? query,
  }) async {
    try {
      final res = await _dio.get('/payments', queryParameters: {
        if (cursor != null) 'cursor': cursor,
        if (filter != null && filter != 'all') 'filter': filter,
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      });
      final data = (res.data as Map).cast<String, Object?>();
      final items = (data['items'] as List<Object?>)
          .map((item) => Payment.fromJson(
                (item as Map).cast<String, Object?>(),
              ))
          .toList();
      return PaymentPage(
        items: items,
        nextCursor: data['nextCursor'] as String?,
      );
    } on DioException catch (e) {
      throw e.error as BankError;
    }
  }
}   

class PaymentPage {
  const PaymentPage({required this.items, required this.nextCursor});

  final List<Payment> items;
  final String? nextCursor;
}