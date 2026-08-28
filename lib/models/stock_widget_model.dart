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
