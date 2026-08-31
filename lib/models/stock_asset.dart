import 'package:flutter/material.dart';

enum AssetCategory {
  gaming,
  usStock,
  euStock,
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
  final String? exchange;

  const StockAsset({
    required this.symbol,
    required this.name,
    required this.category,
    required this.currentPrice,
    required this.currency,
    required this.color,
    this.icon,
    this.exchange,
  });

  String get categoryLabel {
    switch (category) {
      case AssetCategory.gaming:
        return 'Jeux Vidéo';
      case AssetCategory.usStock:
        return 'Action USA';
      case AssetCategory.euStock:
        return 'France & Europe';
      case AssetCategory.crypto:
        return 'Crypto';
      case AssetCategory.marketIndex:
        return 'Indice & Matières';
    }
  }
}
