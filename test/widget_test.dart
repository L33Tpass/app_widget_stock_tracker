import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:app_widget_stock_tracker/main.dart';
import 'package:app_widget_stock_tracker/models/widget_stock_item.dart';
import 'package:app_widget_stock_tracker/models/stock_widget_model.dart';
import 'package:app_widget_stock_tracker/widgets/stock_widget_card.dart';
import 'package:app_widget_stock_tracker/widgets/stock_item_tile.dart';

void main() {
  testWidgets('Home page displays empty state and opens config on click', (WidgetTester tester) async {
    await tester.pumpWidget(const StockTrackerApp());
    await tester.pumpAndSettle();

    // Verify initial prompt text
    expect(
      find.text('Ajoutez votre premier Widget sur votre accueil en cliquant n’importe où sur cette page'),
      findsOneWidget,
    );

    // Verify floating action button text
    expect(find.text('Ajouter un Widget'), findsOneWidget);

    // Tap on the empty state text
    await tester.tap(find.text('Ajoutez votre premier Widget sur votre accueil en cliquant n’importe où sur cette page'));
    await tester.pumpAndSettle();

    // Verify we navigated to config screen
    expect(find.text('Configurer le Widget'), findsOneWidget);
    expect(find.text('Prévisualisation du Widget'), findsOneWidget);

    // Validate widget creation by clicking checkmark in top right
    await tester.tap(find.byIcon(Icons.check).first);
    await tester.pumpAndSettle();

    // Verify we are back on home screen and widget is now displayed
    expect(find.byType(StockWidgetCard), findsOneWidget);
    expect(
      find.text('Ajoutez votre premier Widget sur votre accueil en cliquant n’importe où sur cette page'),
      findsNothing,
    );
  });

  testWidgets('StockWidgetCard sorts items with highest variation at the top', (WidgetTester tester) async {
    final now = DateTime.now();
    final model = StockWidgetModel(
      id: 'test-widget',
      lastUpdated: now,
      items: [
        WidgetStockItem(
          id: '1',
          symbol: 'TSLA',
          customName: 'Tesla Vince',
          purchaseDate: now.subtract(const Duration(days: 30)),
          initialPrice: 200.0,
          currentPrice: 180.0, // -10%
        ),
        WidgetStockItem(
          id: '2',
          symbol: 'NVDA',
          customName: 'Nvidia IA',
          purchaseDate: now.subtract(const Duration(days: 100)),
          initialPrice: 100.0,
          currentPrice: 130.0, // +30%
        ),
        WidgetStockItem(
          id: '3',
          symbol: 'AAPL',
          customName: 'Apple PEA',
          purchaseDate: now.subtract(const Duration(days: 60)),
          initialPrice: 200.0,
          currentPrice: 210.0, // +5%
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockWidgetCard(widgetModel: model),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Check sorted order
    final sorted = model.sortedItems;
    expect(sorted[0].symbol, 'NVDA'); // +30%
    expect(sorted[1].symbol, 'AAPL'); // +5%
    expect(sorted[2].symbol, 'TSLA'); // -10%

    // Verify UI has 3 stock tiles
    expect(find.byType(StockItemTile), findsNWidgets(3));
    expect(find.text('+30.00%'), findsOneWidget);
    expect(find.text('+5.00%'), findsOneWidget);
    expect(find.text('-10.00%'), findsOneWidget);
  });
}
