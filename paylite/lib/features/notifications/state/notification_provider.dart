import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.paymentId,
  });

  final String id;
  final String title;
  final String body;
  final String paymentId;
}

final notificationProvider =
    NotifierProvider<NotificationNotifier, List<AppNotification>>(
  NotificationNotifier.new,
);

class NotificationNotifier extends Notifier<List<AppNotification>> {
  @override
  List<AppNotification> build() => const [];

  void addPaymentReceived({required String paymentId, required int amountPaise}) {
    state = [
      AppNotification(
        id: paymentId,
        title: 'Payment received',
        body: '₹${(amountPaise / 100).toStringAsFixed(2)} received',
        paymentId: paymentId,
      ),
      ...state.where((item) => item.id != paymentId),
    ];
  }
}
