import 'package:dio/dio.dart';
import 'bank_error.dart';

class ErrorMapper {
  static BankError map(DioException e) {
    if (e.response == null) {
      return const Network();
    }

    final status = e.response!.statusCode ?? 0;
    final data = e.response!.data;
    final error = data is Map ? data['error'] : null;

    if (error is Map) {
      final code = error['code'] as String?;
      final message = error['message'] as String?;

      return switch (code) {
        'UNAUTHENTICATED' || 'UNAUTHORIZED' => Unauthorized(
          message ?? 'Please sign in again.',
        ),
        'VPA_NOT_FOUND' => VpaNotFound(
          message ?? 'No account found for this UPI ID.',
        ),
        'INSUFFICIENT_FUNDS' => InsufficientFunds(
          message ?? 'Insufficient balance.',
        ),
        'LIMIT_EXCEEDED' => LimitExceeded(
          message ?? 'Transaction limit exceeded.',
        ),
        'EXPIRED' => Expired(
          message ?? 'This request has expired.',
        ),
        _ => _byStatus(status, message),
      };
    }

    return _byStatus(status, null);
  }

  static BankError _byStatus(int status, String? message) {
    return switch (status) {
      401 => Unauthorized(message ?? 'Please sign in again.'),
      402 => InsufficientFunds(message ?? 'Insufficient balance.'),
      429 => LimitExceeded(message ?? 'Transaction limit exceeded.'),
      >= 500 => Server(message ?? 'Something went wrong on our end.'),
      _ => Unknown(message ?? 'An unexpected error occurred.'),
    };
  }
}   