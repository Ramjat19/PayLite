import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paylite/features/payments/domain/models/payment.dart';
import 'package:paylite/features/payments/state/payment_flow_provider.dart';

final paymentStatusProvider = StreamProvider.autoDispose.family<Payment, String>(
  (ref, paymentId) {
    final controller = StreamController<Payment>();
    var disposed = false;
    Timer? timer;

    ref.onDispose(() {
      disposed = true;
      timer?.cancel();
      controller.close();
    });

    Future<void> poll() async {
      try {
        final payment = await ref.read(paymentRepositoryProvider).getStatus(paymentId);
        if (disposed) return;
        controller.add(payment);
        if (payment.status != PaymentStatus.pending) {
          await controller.close();
          return;
        }
      } catch (error, stackTrace) {
        if (!disposed) controller.addError(error, stackTrace);
        await controller.close();
        return;
      }

      var polls = 0;
      timer = Timer.periodic(const Duration(seconds: 5), (_) async {
        if (disposed || polls >= 24) {
          timer?.cancel();
          await controller.close();
          return;
        }
        polls++;
        try {
          final payment = await ref.read(paymentRepositoryProvider).getStatus(paymentId);
          if (disposed) return;
          controller.add(payment);
          if (payment.status != PaymentStatus.pending || polls >= 24) {
            timer?.cancel();
            await controller.close();
          }
        } catch (error, stackTrace) {
          timer?.cancel();
          if (!disposed) controller.addError(error, stackTrace);
          await controller.close();
        }
      });
    }

    unawaited(poll());
    return controller.stream;
  },
);