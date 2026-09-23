import 'package:dio/dio.dart';
import 'package:paylite/core/network/api_client.dart';
import 'package:paylite/core/errors/bank_error.dart';
import 'package:paylite/features/vpa/domain/models/vpa.dart';

class VpaRepository {
  final Dio _dio = ApiClient().dio;

  Future<Vpa> lookup(String address) async {
    try {
      final res = await _dio.get('/vpa/${Uri.encodeComponent(address)}');
      return Vpa.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw e.error as BankError;
    }
  }
}   