String formatMoney(int paise) {
  final rupees = (paise / 100).toStringAsFixed(2);
  return '₹$rupees';
}  