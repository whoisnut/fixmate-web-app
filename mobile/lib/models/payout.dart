class PayoutResponse {
  final String id;
  final String userId;
  final double amount;
  final String method;
  final String status;
  final String paymentAccount;
  final String? reason;
  final DateTime requestedAt;
  final DateTime? processedAt;

  PayoutResponse({
    required this.id,
    required this.userId,
    required this.amount,
    required this.method,
    required this.status,
    required this.paymentAccount,
    this.reason,
    required this.requestedAt,
    this.processedAt,
  });

  factory PayoutResponse.fromJson(Map<String, dynamic> json) {
    return PayoutResponse(
      id: json['id'],
      userId: json['user_id'],
      amount: (json['amount'] as num).toDouble(),
      method: json['method'],
      status: json['status'],
      paymentAccount: json['payment_account'],
      reason: json['reason'],
      requestedAt: DateTime.parse(json['requested_at']),
      processedAt: json['processed_at'] != null
          ? DateTime.parse(json['processed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'method': method,
      'status': status,
      'payment_account': paymentAccount,
      'reason': reason,
      'requested_at': requestedAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }
}
