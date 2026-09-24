import 'package:paylite/core/utils/json_readers.dart';
import 'package:paylite/features/vpa/domain/models/vpa.dart';

enum SplitParticipantStatus {
  pending,
  paid,
  declined,
  expired;

  static SplitParticipantStatus fromJson(Object? value) {
    final String normalised = _normaliseEnum(value);
    return switch (normalised) {
      'pending' => SplitParticipantStatus.pending,
      'paid' => SplitParticipantStatus.paid,
      'declined' => SplitParticipantStatus.declined,
      'expired' => SplitParticipantStatus.expired,
      _ => throw FormatException('Unknown split participant status: $value.'),
    };
  }
}

/// One recipient and their allocated portion of a split bill.
class SplitParticipant {
  const SplitParticipant({
    required this.vpa,
    required this.amountPaise,
    required this.status,
  });

  factory SplitParticipant.fromJson(Map<String, Object?> json) {
    return SplitParticipant(
      vpa: Vpa.fromJson(readRequiredMap(json, 'vpa')),
      amountPaise: readRequiredInt(json, 'amountPaise'),
      status: SplitParticipantStatus.fromJson(json['status']),
    );
  }

  final Vpa vpa;
  final int amountPaise;
  final SplitParticipantStatus status;

  Map<String, Object?> toJson() => <String, Object?>{
    'vpa': vpa.toJson(),
    'amountPaise': amountPaise,
    'status': status.name.toUpperCase(),
  };

  @override
  bool operator ==(Object other) {
    return other is SplitParticipant &&
        other.vpa == vpa &&
        other.amountPaise == amountPaise &&
        other.status == status;
  }

  @override
  int get hashCode => Object.hash(vpa, amountPaise, status);
}

/// A bill divided between two to ten recipients.
class SplitGroup {
  SplitGroup({
    required this.id,
    required this.totalPaise,
    required List<SplitParticipant> participants,
  }) : participants = List<SplitParticipant>.unmodifiable(participants) {
    if (participants.length < 2 || participants.length > 10) {
      throw ArgumentError.value(
        participants.length,
        'participants',
        'A split group must have between 2 and 10 participants.',
      );
    }
  }

  factory SplitGroup.fromJson(Map<String, Object?> json) {
    final List<SplitParticipant> participants =
        readRequiredList(json, 'participants')
            .map((Object? participant) {
              if (participant is! Map<String, Object?>) {
                throw FormatException(
                  'Each split participant must be an object.',
                );
              }
              return SplitParticipant.fromJson(participant);
            })
            .toList(growable: false);

    return SplitGroup(
      id: readRequiredString(json, 'id'),
      totalPaise: readRequiredInt(json, 'totalPaise'),
      participants: participants,
    );
  }

  final String id;
  final int totalPaise;
  final List<SplitParticipant> participants;

  int get allocatedPaise => participants.fold(
    0,
    (int total, SplitParticipant participant) =>
        total + participant.amountPaise,
  );

  bool get hasExactAllocation => allocatedPaise == totalPaise;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'totalPaise': totalPaise,
    'participants': participants
        .map((SplitParticipant participant) => participant.toJson())
        .toList(growable: false),
  };

  @override
  bool operator ==(Object other) {
    if (other is! SplitGroup ||
        other.id != id ||
        other.totalPaise != totalPaise ||
        other.participants.length != participants.length) {
      return false;
    }

    for (var index = 0; index < participants.length; index++) {
      if (other.participants[index] != participants[index]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, totalPaise, Object.hashAll(participants));
}

String _normaliseEnum(Object? value) {
  if (value is String) {
    return value.trim().toLowerCase();
  }

  throw FormatException('Expected an enum string, received $value.');
}
