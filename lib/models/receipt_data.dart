class ReceiptData {
  final String merchant;
  final double amount;
  final DateTime date;
  final String category;
  final List<String> items;
  final double confidence;
  final String? notes;

  ReceiptData({
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.items = const [],
    this.confidence = 0.0,
    this.notes,
  });

  factory ReceiptData.fromJson(Map<String, dynamic> json) {
    return ReceiptData(
      merchant: json['merchant'] as String? ?? 'Unknown',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : double.tryParse(
                  json['amount'].toString().replaceAll(RegExp(r'[^\d.]'), ''),
                ) ??
                0.0,
      date: _parseDate(json['date']),
      category: json['category'] as String? ?? 'Other',
      items:
          (json['items'] as List<dynamic>?)
              ?.map((item) => item.toString())
              .toList() ??
          [],
      confidence: (json['confidence'] is num)
          ? (json['confidence'] as num).toDouble()
          : 0.0,
      notes: json['notes'] as String?,
    );
  }

  static DateTime _parseDate(dynamic dateStr) {
    if (dateStr == null) return DateTime.now();

    try {
      // Try parsing DD/MM/YYYY format
      if (dateStr is String && dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          return DateTime(
            int.parse(parts[2]), // year
            int.parse(parts[1]), // month
            int.parse(parts[0]), // day
          );
        }
      }
      // Try parsing ISO format
      return DateTime.parse(dateStr.toString());
    } catch (e) {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'merchant': merchant,
      'amount': amount,
      'date':
          '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
      'category': category,
      'items': items,
      'confidence': confidence,
      'notes': notes,
    };
  }

  @override
  String toString() {
    return 'ReceiptData(merchant: $merchant, amount: $amount, date: $date, category: $category, confidence: $confidence)';
  }
}
