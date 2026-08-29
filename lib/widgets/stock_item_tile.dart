import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/widget_stock_item.dart';

class StockItemTile extends StatelessWidget {
  final WidgetStockItem item;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool showEditControls;
  final bool isLoading;

  const StockItemTile({
    super.key,
    required this.item,
    this.onDelete,
    this.onEdit,
    this.showEditControls = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = item.isPositive;
    final color = isPositive ? const Color(0xFF1B873F) : const Color(0xFFD93025);
    final bgColor = isPositive ? const Color(0xFFE6F4EA) : const Color(0xFFFCE8E6);

    final currencyFormatter = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: '€',
      decimalDigits: 2,
    );
    final priceStr = currencyFormatter.format(item.currentPrice);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: User custom name (and ticker symbol in small subscript)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.customName,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (item.customName.toUpperCase() != item.symbol.toUpperCase())
                  Text(
                    item.symbol,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
              ],
            ),
          ),

          // Price in EUR
          Text(
            priceStr,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.normal,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 8),

          // Right: Variation percentage formatted or Loading state
          if (isLoading)
            _buildLoadingBadge()
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                item.formattedVariation,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),

          if (showEditControls) ...[
            const SizedBox(width: 4),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blueGrey),
                onPressed: onEdit,
                splashRadius: 18,
                tooltip: 'Modifier',
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                onPressed: onDelete,
                splashRadius: 18,
                tooltip: 'Supprimer',
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.8,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7280)),
            ),
          ),
          SizedBox(width: 4),
          Text(
            '··· %',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}
