import 'package:flutter/material.dart';
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                if (item.customName.toUpperCase() != item.symbol.toUpperCase())
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.symbol,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Right: Variation percentage formatted or Loading state
          if (isLoading)
            _buildLoadingBadge()
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                    size: 20,
                    color: color,
                  ),
                  Text(
                    item.formattedVariation,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6B7280)),
            ),
          ),
          SizedBox(width: 6),
          Text(
            '··· %',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
