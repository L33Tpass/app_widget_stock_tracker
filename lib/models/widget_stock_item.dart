class WidgetStockItem {
  final String id;
  final String symbol;
  String customName;
  DateTime purchaseDate;
  double initialPrice;
  double currentPrice;

  WidgetStockItem({
    required this.id,
    required this.symbol,
    required this.customName,
    required this.purchaseDate,
    required this.initialPrice,
    required this.currentPrice,
  });

  double get variationPercentage {
    if (initialPrice <= 0) return 0.0;
    return ((currentPrice - initialPrice) / initialPrice) * 100.0;
  }

  bool get isPositive => variationPercentage >= 0;

  String get formattedVariation {
    final v = variationPercentage;
    if (v >= 0) {
      return '+${v.toStringAsFixed(2)}%';
    } else {
      return '${v.toStringAsFixed(2)}%';
    }
  }

  WidgetStockItem copyWith({
    String? id,
    String? symbol,
    String? customName,
    DateTime? purchaseDate,
    double? initialPrice,
    double? currentPrice,
  }) {
    return WidgetStockItem(
      id: id ?? this.id,
      symbol: symbol ?? this.symbol,
      customName: customName ?? this.customName,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      initialPrice: initialPrice ?? this.initialPrice,
      currentPrice: currentPrice ?? this.currentPrice,
    );
  }
}
