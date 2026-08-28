import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_widget_model.dart';
import 'stock_item_tile.dart';

class StockWidgetCard extends StatefulWidget {
  final StockWidgetModel widgetModel;
  final VoidCallback? onRefresh;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onPin;
  final bool isPreview;

  const StockWidgetCard({
    super.key,
    required this.widgetModel,
    this.onRefresh,
    this.onEdit,
    this.onDelete,
    this.onPin,
    this.isPreview = false,
  });

  @override
  State<StockWidgetCard> createState() => _StockWidgetCardState();
}

class _StockWidgetCardState extends State<StockWidgetCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _handleRefresh() {
    _rotationController.forward(from: 0.0);
    if (widget.onRefresh != null) {
      widget.onRefresh!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final sortedItems = widget.widgetModel.sortedItems;
    final dateStr = DateFormat('dd/MM/yyyy HH:mm:ss').format(widget.widgetModel.lastUpdated);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: widget.isPreview
              ? const Color(0xFF6366F1).withValues(alpha: 0.3)
              : Colors.black.withValues(alpha: 0.04),
          width: widget.isPreview ? 1.5 : 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header: Top-left date/time & Top-right refresh button + options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Top-left: Date & Time of last update
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 15,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                              letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Top-right: Refresh arrow icon & optional menu
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RotationTransition(
                        turns: Tween(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _rotationController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          iconSize: 20,
                          color: const Color(0xFF374151),
                          tooltip: 'Actualiser les cours',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: _handleRefresh,
                        ),
                      ),
                      if (!widget.isPreview && (widget.onEdit != null || widget.onDelete != null))
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            size: 19,
                            color: Colors.grey.shade600,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          onSelected: (val) {
                            if (val == 'pin' && widget.onPin != null) {
                              widget.onPin!();
                            } else if (val == 'edit' && widget.onEdit != null) {
                              widget.onEdit!();
                            } else if (val == 'delete' && widget.onDelete != null) {
                              widget.onDelete!();
                            }
                          },
                          itemBuilder: (context) => [
                            if (widget.onPin != null)
                              const PopupMenuItem(
                                value: 'pin',
                                child: Row(
                                  children: [
                                    Icon(Icons.push_pin_outlined, size: 18, color: Color(0xFF4F46E5)),
                                    SizedBox(width: 8),
                                    Text('Épingler sur l\'accueil'),
                                  ],
                                ),
                              ),
                            if (widget.onEdit != null)
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 8),
                                    Text('Modifier'),
                                  ],
                                ),
                              ),
                            if (widget.onDelete != null)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Supprimer', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8),
              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 8),

              // Stock items list sorted by variation (highest to lowest)
              if (sortedItems.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.candlestick_chart_outlined, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Aucune action suivie pour l’instant',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
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
      ),
    );
  }
}
