import 'dart:convert';
import 'widget_stock_item.dart';

class StockWidgetModel {
  final String id;
  String title;
  List<WidgetStockItem> items;
  DateTime lastUpdated;

  StockWidgetModel({
    required this.id,
    this.title = 'Suivi des Actions',
    required this.items,
    required this.lastUpdated,
  });

  /// Items sorted by variation percentage descending (highest in top, lowest in bottom)
  List<WidgetStockItem> get sortedItems {
    final list = List<WidgetStockItem>.from(items);
    list.sort((a, b) => b.variationPercentage.compareTo(a.variationPercentage));
    return list;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'items': items.map((i) => i.toJson()).toList(),
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory StockWidgetModel.fromJson(Map<String, dynamic> json) => StockWidgetModel(
    id: json['id'] as String,
    title: (json['title'] as String?) ?? 'Suivi des Actions',
    items: (json['items'] as List<dynamic>?)
            ?.map((e) => WidgetStockItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [],
    lastUpdated: json['lastUpdated'] != null
        ? DateTime.parse(json['lastUpdated'] as String)
        : DateTime.now(),
  );

  String toJsonString() => jsonEncode(toJson());

  factory StockWidgetModel.fromJsonString(String jsonStr) =>
      StockWidgetModel.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);

  StockWidgetModel copyWith({
    String? id,
    String? title,
    List<WidgetStockItem>? items,
    DateTime? lastUpdated,
  }) {
    return StockWidgetModel(
      id: id ?? this.id,
      title: title ?? this.title,
      items: items != null
          ? items.map((e) => e.copyWith()).toList()
          : this.items.map((e) => e.copyWith()).toList(),
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
