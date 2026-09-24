import 'package:flutter_test/flutter_test.dart';
import 'package:paylite/features/accounts/domain/models/account.dart';
import 'package:paylite/features/auth/domain/models/auth_session.dart';
import 'package:paylite/features/collect/domain/models/collect_request.dart';
import 'package:paylite/features/payments/domain/models/payment.dart';
import 'package:paylite/features/split/domain/models/split_group.dart';
import 'package:paylite/features/vpa/domain/models/vpa.dart';

void main() {
  const Map<String, Object?> vpaJson = <String, Object?>{
    'address': 'merchant@paylite',
    'verifiedName': 'Merchant Store',
    'bankName': 'PayLite Bank',
  };

  group('domain models', () {
    test('account preserves money as integer paise', () {
      final Account account = Account.fromJson(<String, Object?>{
        'id': 'account-1',
        'maskedNumber': 'XXXX1234',
        'balancePaise': 125050,
        'primaryVpa': 'priya@paylite',
      });

      expect(account.balancePaise, 125050);
      expect(account.primaryVpa, 'priya@paylite');
    });

    test('rejects a fractional money value', () {
      expect(
        () => Account.fromJson(<String, Object?>{
          'id': 'account-1',
          'maskedNumber': 'XXXX1234',
          'balancePaise': 12.50,
          'primaryVpa': 'priya@paylite',
        }),
        throwsFormatException,
      );
    });

    test('auth session reads the device-bound login response', () {
      final AuthSession session = AuthSession.fromJson(<String, Object?>{
        'token': 'session-token',
        'deviceId': 'device-1',
      });

      expect(session.deviceId, 'device-1');
    });

    test(
      'payment recognises tri-state status and converts timestamps to local',
      () {
        final Payment payment = Payment.fromJson(<String, Object?>{
          'id': 'payment-1',
          'direction': 'SENT',
          'counterparty': vpaJson,
          'amountPaise': 20000,
          'note': 'Vegetables',
          'status': 'PENDING',
          'upiRef': null,
          'createdAt': '2026-09-22T10:30:00.000Z',
        });

        expect(payment.direction, PaymentDirection.sent);
        expect(payment.status, PaymentStatus.pending);
        expect(payment.upiRef, isNull);
        expect(payment.createdAt.isUtc, isFalse);
        expect(payment.createdAt.toUtc(), DateTime.utc(2026, 9, 22, 10, 30));
      },
    );

    test('collect request considers its local expiry time', () {
      final CollectRequest request = CollectRequest.fromJson(<String, Object?>{
        'id': 'collect-1',
        'from': vpaJson,
        'to': <String, Object?>{
          'address': 'priya@paylite',
          'verifiedName': 'Priya Sharma',
          'bankName': 'PayLite Bank',
        },
        'amountPaise': 50000,
        'status': 'EXPIRED',
        'expiresAt': '2026-09-21T10:30:00.000Z',
      });

      expect(request.status, CollectRequestStatus.expired);
      expect(request.isExpired, isTrue);
    });

    test('split group keeps participants immutable and reports allocation', () {
      final SplitGroup group = SplitGroup.fromJson(<String, Object?>{
        'id': 'split-1',
        'totalPaise': 10000,
        'participants': <Object?>[
          <String, Object?>{
            'vpa': vpaJson,
            'amountPaise': 3334,
            'status': 'PENDING',
          },
          <String, Object?>{
            'vpa': <String, Object?>{
              'address': 'asha@paylite',
              'verifiedName': 'Asha Rao',
              'bankName': 'PayLite Bank',
            },
            'amountPaise': 3333,
            'status': 'PAID',
          },
          <String, Object?>{
            'vpa': <String, Object?>{
              'address': 'ramesh@paylite',
              'verifiedName': 'Ramesh Kumar',
              'bankName': 'PayLite Bank',
            },
            'amountPaise': 3333,
            'status': 'PENDING',
          },
        ],
      });

      expect(group.allocatedPaise, 10000);
      expect(group.hasExactAllocation, isTrue);
      expect(
        () => group.participants.add(
          const SplitParticipant(
            vpa: Vpa(
              address: 'new@paylite',
              verifiedName: 'New Person',
              bankName: 'PayLite Bank',
            ),
            amountPaise: 1,
            status: SplitParticipantStatus.pending,
          ),
        ),
        throwsUnsupportedError,
      );
    });
    test('vpa preserves verified name and bank name', () {
      final Vpa vpa = Vpa.fromJson(vpaJson);

      expect(vpa.address, 'merchant@paylite');
      expect(vpa.verifiedName, 'Merchant Store');
      expect(vpa.bankName, 'PayLite Bank');
    });
    // test('vpa rejects an invalid address', () {
    //   expect(
    //     () => Vpa.fromJson(<String, Object?>{
    //       'address': 'invalid-vpa',
    //       'verifiedName': 'Invalid VPA',
    //       'bankName': 'PayLite Bank',
    //     }),
    //     throwsFormatException,
    //   );
    // });
    test('vpa rejects an empty verified name', () {
      expect(
        () => Vpa.fromJson(<String, Object?>{
          'address': 'valid@paylite',
          'verifiedName': '',
          'bankName': 'PayLite Bank',
        }),
        throwsFormatException,
      );
    });
    test('vpa rejects an empty bank name', () {
      expect(
        () => Vpa.fromJson(<String, Object?>{
          'address': 'valid@paylite',
          'verifiedName': 'Valid VPA',
          'bankName': '',
        }),
        throwsFormatException,
      );
    });
    test('vpa rejects a null bank name', () {
        expect(
          () => Vpa.fromJson(<String, Object?>{
            'address': 'valid@paylite',
            'verifiedName': 'Valid VPA',
            'bankName': null,
          }),
          throwsFormatException,
        );
      });
      test('vpa accepts a valid VPA', () {
        final Vpa vpa = Vpa.fromJson(<String, Object?>{
          'address': 'valid@paylite',
          'verifiedName': 'Valid VPA',
          'bankName': 'PayLite Bank',
        });
        expect(vpa.address, 'valid@paylite');
        expect(vpa.verifiedName, 'Valid VPA');
        expect(vpa.bankName, 'PayLite Bank');
      });
  });
}
