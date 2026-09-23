import 'package:paylite/core/utils/json_readers.dart';
import 'package:paylite/features/vpa/domain/models/vpa.dart';

enum PaymentDirection {
  sent,
  received;

  static PaymentDirection fromJson(Object? value) {
    return switch (_normaliseEnum(value)) {
      'sent' => PaymentDirection.sent,
      'received' => PaymentDirection.received,
      _ => throw FormatException('Unknown payment direction: $value.'),
    };
  }
}

enum PaymentStatus {
  success,
  pending,
  failed;

  static PaymentStatus fromJson(Object? value) {
    return switch (_normaliseEnum(value)) {
      'success' => PaymentStatus.success,
      'pending' => PaymentStatus.pending,
      'failed' => PaymentStatus.failed,
      _ => throw FormatException('Unknown payment status: $value.'),
    };
  }
}

/// A UPI transfer. Its [status] is deliberately tri-state: a pending transfer
/// must never be displayed as failed before the server confirms that outcome.
class Payment {
  const Payment({
    required this.id,
    required this.direction,
    required this.counterparty,
    required this.amountPaise,
    required this.note,
    required this.status,
    required this.upiRef,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, Object?> json) {
    return Payment(
      id: readRequiredString(json, 'id'),
      direction: PaymentDirection.fromJson(json['direction']),
      counterparty: Vpa.fromJson(readRequiredMap(json, 'counterparty')),
      amountPaise: readRequiredInt(json, 'amountPaise'),
      note: readNullableString(json, 'note'),
      status: PaymentStatus.fromJson(json['status']),
      upiRef: readNullableString(json, 'upiRef'),
      createdAt: readUtcDateTimeAsLocal(json, 'createdAt'),
    );
  }

  final String id;
  final PaymentDirection direction;
  final Vpa counterparty;
  final int amountPaise;
  final String? note;
  final PaymentStatus status;
  final String? upiRef;
  final DateTime createdAt;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'direction': direction.name.toUpperCase(),
    'counterparty': counterparty.toJson(),
    'amountPaise': amountPaise,
    'note': note,
    'status': status.name.toUpperCase(),
    'upiRef': upiRef,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) {
    return other is Payment &&
        other.id == id &&
        other.direction == direction &&
        other.counterparty == counterparty &&
        other.amountPaise == amountPaise &&
        other.note == note &&
        other.status == status &&
        other.upiRef == upiRef &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    direction,
    counterparty,
    amountPaise,
    note,
    status,
    upiRef,
    createdAt,
  );
}

String _normaliseEnum(Object? value) {
  if (value is String) {
    return value.trim().toLowerCase();
  }

  throw FormatException('Expected an enum string, received $value.');
}
