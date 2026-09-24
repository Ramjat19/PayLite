class ParsedQr {
  final String vpa;
  final String name;
  final int amountPaise; // 0 if not in QR

  const ParsedQr({
    required this.vpa,
    required this.name,
    this.amountPaise = 0,
  });
}

class QrParser {
  static ParsedQr? parse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme.toLowerCase() != 'upi' ||
        uri.host.toLowerCase() != 'pay') {
      return null;
    }

    final params = uri.queryParameters;

    final pa = params['pa']?.trim().toLowerCase();
    if (pa == null || !pa.contains('@')) return null;

    final pn = params['pn']?.trim() ?? 'Unknown';

    int amountPaise = 0;
    final am = params['am']?.trim();
    if (am != null && double.tryParse(am) != null) {
      amountPaise = (double.parse(am) * 100).round();
    }

    return ParsedQr(vpa: pa, name: pn, amountPaise: amountPaise);
  }
}   