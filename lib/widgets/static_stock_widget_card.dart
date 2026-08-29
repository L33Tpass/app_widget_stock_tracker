import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_widget_model.dart';
import 'stock_item_tile.dart';

class StaticStockWidgetCard extends StatelessWidget {
  final StockWidgetModel widgetModel;

  const StaticStockWidgetCard({
    super.key,
    required this.widgetModel,
  });

  @override
  Widget build(BuildContext context) {
    final sortedItems = widgetModel.sortedItems;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(widgetModel.lastUpdated);

    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF374151)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),

          // Stocks
          if (sortedItems.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Aucune action suivie',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
              ),
            )
          else
            ...sortedItems.map(
              (item) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StockItemTile(
                    item: item,
                    showEditControls: false,
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
