import 'package:flutter/material.dart';

enum AssetCategory {
  usStock,
  crypto,
  marketIndex,
}

class StockAsset {
  final String symbol;
  final String name;
  final AssetCategory category;
  final double currentPrice;
  final String currency;
  final Color color;
  final IconData? icon;

  const StockAsset({
    required this.symbol,
    required this.name,
    required this.category,
    required this.currentPrice,
    required this.currency,
    required this.color,
    this.icon,
  });
}
