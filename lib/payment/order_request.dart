class OrderRequest {
  final int amount;
  final String currency;
  final String receipt;
  final bool partialPayment;

  OrderRequest({
    required this.amount,
    required this.currency,
    required this.receipt,
    required this.partialPayment,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'currency': currency,
      'receipt': receipt,
      'partial_payment': partialPayment,
    };
  }
}