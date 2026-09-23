import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:paylite/core/errors/bank_error.dart';
import 'package:paylite/core/network/api_client.dart';
import 'package:paylite/features/collect/domain/models/collect_request.dart';
import 'package:uuid/uuid.dart';

class CollectRepository {
  final Dio _dio = ApiClient().dio;

  Future<List<CollectRequest>> getAll() async {
    try {
      final response = await _dio.get('/collect-requests');
      final data = (response.data as Map).cast<String, Object?>();
      return (data['items'] as List<Object?>)
          .map((item) => CollectRequest.fromJson(
                (item as Map).cast<String, Object?>(),
              ))
          .toList();
    } on DioException catch (error) {
      throw error.error as BankError;
    }
  }

  Future<CollectRequest> create({
    required String vpa,
    required int amountPaise,
  }) async {
    try {
      final response = await _dio.post('/collect-requests', data: {
        'vpa': vpa,
        'amountPaise': amountPaise,
      });
      return CollectRequest.fromJson(
        (response.data as Map).cast<String, Object?>(),
      );
    } on DioException catch (error) {
      throw error.error as BankError;
    }
  }

  Future<CollectRequest> decline(String id) async {
    try {
      final response = await _dio.post('/collect-requests/$id/decline');
      return CollectRequest.fromJson(
        (response.data as Map).cast<String, Object?>(),
      );
    } on DioException catch (error) {
      throw error.error as BankError;
    }
  }

  Future<CollectRequest> pay({
    required CollectRequest request,
    required String pin,
  }) async {
    try {
      final response = await _dio.post(
        '/collect-requests/${request.id}/pay',
        data: {
          'upiPinHash': sha256.convert(utf8.encode(pin)).toString(),
          'idempotencyKey': const Uuid().v4(),
        },
      );
      final data = (response.data as Map).cast<String, Object?>();
      return CollectRequest.fromJson(
        (data['request'] as Map).cast<String, Object?>(),
      );
    } on DioException catch (error) {
      throw error.error as BankError;
    }
  }
}