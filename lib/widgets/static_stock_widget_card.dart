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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 5),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                Icon(Icons.refresh_rounded, size: 18, color: Colors.grey.shade700),
              ],
            ),
            const SizedBox(height: 6),
            Divider(height: 1, color: Colors.grey.shade200),
            const SizedBox(height: 6),

            // Stocks
            if (sortedItems.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'Aucune action suivie',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              )
            else
              ...sortedItems.map(
                (item) => StockItemTile(
                  item: item,
                  showEditControls: false,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
