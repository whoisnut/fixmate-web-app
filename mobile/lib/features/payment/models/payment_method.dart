class PaymentMethod {
  final String id;
  final String type; // 'credit_card', 'debit_card'
  final String cardholderName;
  final String lastFourDigits;
  final String expiryMonth;
  final String expiryYear;
  final String brand; // 'visa', 'mastercard', 'amex'
  final bool isDefault;
  final DateTime createdAt;

  PaymentMethod({
    required this.id,
    required this.type,
    required this.cardholderName,
    required this.lastFourDigits,
    required this.expiryMonth,
    required this.expiryYear,
    required this.brand,
    required this.isDefault,
    required this.createdAt,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      type: json['type'],
      cardholderName: json['cardholder_name'],
      lastFourDigits: json['last_four_digits'],
      expiryMonth: json['expiry_month'].toString().padLeft(2, '0'),
      expiryYear: json['expiry_year'].toString(),
      brand: json['brand'],
      isDefault: json['is_default'] == "1" || json['is_default'] == true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'cardholder_name': cardholderName,
      'last_four_digits': lastFourDigits,
      'expiry_month': expiryMonth,
      'expiry_year': expiryYear,
      'brand': brand,
      'is_default': isDefault ? "1" : "0",
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get cardDisplay => '$brand •••• ${lastFourDigits}';
  String get expiryDisplay => '$expiryMonth/$expiryYear';
  bool get isExpired {
    final now = DateTime.now();
    final expiry = DateTime(int.parse(expiryYear), int.parse(expiryMonth));
    return expiry.isBefore(now);
  }
}
