import 'package:paylite/core/utils/json_readers.dart';

/// A verified UPI virtual payment address.
class Vpa {
  const Vpa({
    required this.address,
    required this.verifiedName,
    required this.bankName,
  });

  factory Vpa.fromJson(Map<String, Object?> json) {
    return Vpa(
      address: readRequiredString(json, 'address'),
      verifiedName: readRequiredString(json, 'verifiedName'),
      bankName: readRequiredString(json, 'bankName'),
    );
  }

  final String address;
  final String verifiedName;
  final String bankName;

  Map<String, Object?> toJson() => <String, Object?>{
    'address': address,
    'verifiedName': verifiedName,
    'bankName': bankName,
  };

  @override
  bool operator ==(Object other) {
    return other is Vpa &&
        other.address == address &&
        other.verifiedName == verifiedName &&
        other.bankName == bankName;
  }

  @override
  int get hashCode => Object.hash(address, verifiedName, bankName);
}
