import 'package:go_router/go_router.dart';

/// Keeps notification delivery independent from payment presentation.
class NotificationService {
  NotificationService(this.router);

  final GoRouter router;

  void handleTap(String payload) {
    final paymentId = _paymentIdFromPayload(payload);
    if (paymentId != null) {
      router.go('/pay/status/$paymentId');
    }
  }

  String? _paymentIdFromPayload(String payload) {
    final uri = Uri.tryParse(payload);
    if (uri != null && uri.pathSegments.length >= 3 &&
        uri.pathSegments[0] == 'pay' && uri.pathSegments[1] == 'status') {
      return uri.pathSegments[2];
    }

    const prefix = 'payment:';
    return payload.startsWith(prefix) ? payload.substring(prefix.length) : null;
  }
}
