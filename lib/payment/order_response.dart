class OrderResponse {
  final String id;
  final int amount;
  final String currency;
  final String receipt;

  OrderResponse({
    required this.id,
    required this.amount,
    required this.currency,
    required this.receipt,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      id: json['id'],
      amount: json['amount'],
      currency: json['currency'],
      receipt: json['receipt'],
    );
  }
}