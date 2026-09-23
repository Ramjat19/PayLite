import 'package:paylite/core/utils/json_readers.dart';
import 'package:paylite/features/vpa/domain/models/vpa.dart';

enum CollectRequestStatus {
  pending,
  paid,
  declined,
  expired;

  static CollectRequestStatus fromJson(Object? value) {
    final String normalised = _normaliseEnum(value);
    return switch (normalised) {
      'pending' => CollectRequestStatus.pending,
      'paid' => CollectRequestStatus.paid,
      'declined' => CollectRequestStatus.declined,
      'expired' => CollectRequestStatus.expired,
      _ => throw FormatException('Unknown collect request status: $value.'),
    };
  }
}

/// A request for the recipient to make a UPI payment before [expiresAt].
class CollectRequest {
  const CollectRequest({
    required this.id,
    required this.from,
    required this.to,
    required this.amountPaise,
    required this.status,
    required this.expiresAt,
  });

  factory CollectRequest.fromJson(Map<String, Object?> json) {
    return CollectRequest(
      id: readRequiredString(json, 'id'),
      from: Vpa.fromJson(readRequiredMap(json, 'from')),
      to: Vpa.fromJson(readRequiredMap(json, 'to')),
      amountPaise: readRequiredInt(json, 'amountPaise'),
      status: CollectRequestStatus.fromJson(json['status']),
      expiresAt: readUtcDateTimeAsLocal(json, 'expiresAt'),
    );
  }

  final String id;
  final Vpa from;
  final Vpa to;
  final int amountPaise;
  final CollectRequestStatus status;
  final DateTime expiresAt;

  bool get isExpired =>
      status == CollectRequestStatus.expired ||
      !expiresAt.isAfter(DateTime.now());

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'from': from.toJson(),
    'to': to.toJson(),
    'amountPaise': amountPaise,
    'status': status.name.toUpperCase(),
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) {
    return other is CollectRequest &&
        other.id == id &&
        other.from == from &&
        other.to == to &&
        other.amountPaise == amountPaise &&
        other.status == status &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode => Object.hash(id, from, to, amountPaise, status, expiresAt);
}

String _normaliseEnum(Object? value) {
  if (value is String) {
    return value.trim().toLowerCase();
  }

  throw FormatException('Expected an enum string, received $value.');
}
