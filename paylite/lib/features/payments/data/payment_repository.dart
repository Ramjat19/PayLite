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
}   