import 'package:paylite/core/utils/json_readers.dart';

/// The signed-in customer's primary bank account.
///
/// [balancePaise] is always integer paise; presentation code is responsible
/// for formatting it as currency.
class Account {
  const Account({
    required this.id,
    required this.maskedNumber,
    required this.balancePaise,
    required this.primaryVpa,
  });

  factory Account.fromJson(Map<String, Object?> json) {
    return Account(
      id: readRequiredString(json, 'id'),
      maskedNumber: readRequiredString(json, 'maskedNumber'),
      balancePaise: readRequiredInt(json, 'balancePaise'),
      primaryVpa: readRequiredString(json, 'primaryVpa'),
    );
  }

  final String id;
  final String maskedNumber;
  final int balancePaise;
  final String primaryVpa;

  Map<String, Object?> toJson() => <String, Object?>{
    'id': id,
    'maskedNumber': maskedNumber,
    'balancePaise': balancePaise,
    'primaryVpa': primaryVpa,
  };

  @override
  bool operator ==(Object other) {
    return other is Account &&
        other.id == id &&
        other.maskedNumber == maskedNumber &&
        other.balancePaise == balancePaise &&
        other.primaryVpa == primaryVpa;
  }

  @override
  int get hashCode => Object.hash(id, maskedNumber, balancePaise, primaryVpa);
}
