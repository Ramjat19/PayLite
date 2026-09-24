import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:paylite/core/network/api_client.dart';
import 'package:paylite/features/payments/data/payment_repository.dart';
import 'package:paylite/features/payments/domain/models/payment.dart';
import 'package:paylite/features/payments/state/payment_flow_provider.dart';
import 'package:paylite/features/presentation/history_screen.dart';
import 'package:paylite/features/vpa/domain/models/vpa.dart';

class _FakePaymentRepository extends PaymentRepository {
  @override
  Future<PaymentPage> getHistory({String? cursor, String? filter, String? query}) async {
    return PaymentPage(items: _payments, nextCursor: null);
  }

  static final _payments = List<Payment>.generate(
    500,
    (index) => Payment(
      id: 'benchmark-$index',
      direction: index.isEven ? PaymentDirection.sent : PaymentDirection.received,
      counterparty: const Vpa(
        address: 'merchant@paylite',
        verifiedName: 'Merchant Store',
        bankName: 'PayLite Bank',
      ),
      amountPaise: 10000 + index,
      note: null,
      status: PaymentStatus.success,
      upiRef: 'BENCHMARK-$index',
      createdAt: DateTime.utc(2026, 1, 1).add(Duration(minutes: index)),
    ),
  );
}

void main() {
  testWidgets('History virtualizes 500 payments and scrolls in profile runs', (tester) async {
    ApiClient().init();
    final stopwatch = Stopwatch()..start();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          paymentRepositoryProvider.overrideWithValue(_FakePaymentRepository()),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    final firstFrameMs = stopwatch.elapsedMicroseconds / 1000;
    final list = find.byType(ListView).last;
    final scrollStart = Stopwatch()..start();
    await tester.drag(list, const Offset(0, -24000));
    await tester.pumpAndSettle();
    final scrollMs = scrollStart.elapsedMicroseconds / 1000;
    stopwatch.stop();

    developer.log(
      'history_500 firstFrameMs=${firstFrameMs.toStringAsFixed(2)} '
      'scrollMs=${scrollMs.toStringAsFixed(2)} '
      'elapsedMs=${(stopwatch.elapsedMicroseconds / 1000).toStringAsFixed(2)}',
      name: 'paylite.performance',
    );

    expect(find.text('Merchant Store'), findsWidgets);
    expect(find.byType(ListView), findsWidgets);
  });
}
