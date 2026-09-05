import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:app_widget_stock_tracker/main.dart';
import 'package:app_widget_stock_tracker/models/widget_stock_item.dart';
import 'package:app_widget_stock_tracker/models/stock_widget_model.dart';
import 'package:app_widget_stock_tracker/models/stock_asset.dart';
import 'package:app_widget_stock_tracker/services/market_data_service.dart';
import 'package:app_widget_stock_tracker/services/native_widget_service.dart';
import 'package:app_widget_stock_tracker/services/widget_storage_service.dart';
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
      isPinned: true,
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

  testWidgets('StockWidgetCard displays inactive state when isPinned is false and triggers onPin on click', (WidgetTester tester) async {
    bool pinClicked = false;
    final now = DateTime.now();
    final model = StockWidgetModel(
      id: 'test-inactive-widget',
      lastUpdated: now,
      isPinned: false,
      items: [
        WidgetStockItem(
          id: '1',
          symbol: 'BTC/EUR',
          customName: 'Bitcoin',
          purchaseDate: now.subtract(const Duration(days: 10)),
          initialPrice: 50000.0,
          currentPrice: 60000.0,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockWidgetCard(
            widgetModel: model,
            onPin: () => pinClicked = true,
            onEdit: () {},
            onDelete: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify inactive text is shown
    expect(find.text('Widget inactif'), findsOneWidget);
    expect(find.text('Cliquer pour l’ajouter à l’écran d’accueil'), findsOneWidget);

    // Verify header components are present and not hidden
    expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
    expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);

    // Tap on the inactive card
    await tester.tap(find.text('Widget inactif'));
    await tester.pumpAndSettle();

    expect(pinClicked, isTrue);

    // Tap on the 3 dots menu
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();

    // Verify 'Modifier' and 'Supprimer' are present, but 'Épingler sur l\'accueil' is NOT present
    expect(find.text('Modifier'), findsOneWidget);
    expect(find.text('Supprimer'), findsOneWidget);
    expect(find.text('Épingler sur l\'accueil'), findsNothing);
  });

  testWidgets('Header refresh and edit buttons work independently when widget is inactive on small screen', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    bool refreshed = false;
    bool edited = false;
    final now = DateTime.now();
    final model = StockWidgetModel(
      id: 'test-inactive-narrow',
      lastUpdated: now,
      isPinned: false,
      items: [
        WidgetStockItem(
          id: '1',
          symbol: 'BTC/EUR',
          customName: 'Bitcoin',
          purchaseDate: now.subtract(const Duration(days: 10)),
          initialPrice: 50000.0,
          currentPrice: 60000.0,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StockWidgetCard(
            widgetModel: model,
            onRefresh: () => refreshed = true,
            onEdit: () => edited = true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify no render overflow occurred on narrow screen
    expect(tester.takeException(), isNull);

    // Tap refresh button in header
    await tester.tap(find.byIcon(Icons.refresh_rounded));
    await tester.pumpAndSettle();
    expect(refreshed, isTrue);

    // Open 3 dots menu and tap Modifier
    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    expect(edited, isTrue);
  });

  test('WidgetStorageService saves and restores widgets correctly', () async {
    final now = DateTime.now();
    final model = StockWidgetModel(
      id: 'stored-widget-1',
      title: 'Mon PEA Actions',
      lastUpdated: now,
      isPinned: true,
      items: [
        WidgetStockItem(
          id: 'item-1',
          symbol: 'AAPL',
          customName: 'Apple Inc',
          purchaseDate: now.subtract(const Duration(days: 15)),
          initialPrice: 150.0,
          currentPrice: 185.0,
        ),
      ],
    );

    final storage = WidgetStorageService();
    await storage.saveWidgets([model]);

    final loaded = await storage.loadWidgets();
    expect(loaded.length, 1);
    expect(loaded.first.id, 'stored-widget-1');
    expect(loaded.first.title, 'Mon PEA Actions');
    expect(loaded.first.items.first.symbol, 'AAPL');
    expect(loaded.first.isPinned, isTrue);
  });

  test('MarketDataService contains Take-Two Interactive and expanded assets', () {
    final service = MarketDataService();
    final allAssets = service.getAllAssets();

    // Verify Take-Two Interactive is present
    final ttwo = service.getAssetBySymbol('TTWO');
    expect(ttwo, isNotNull);
    expect(ttwo!.name, contains('Take-Two'));
    expect(ttwo.symbol, 'TTWO');

    // Verify gaming category
    final gamingAssets = allAssets.where((a) => a.category == AssetCategory.gaming).toList();
    expect(gamingAssets.length, greaterThanOrEqualTo(5));
    expect(gamingAssets.any((a) => a.symbol == 'TTWO'), isTrue);
    expect(gamingAssets.any((a) => a.symbol == 'EA'), isTrue);

    // Verify European & French stocks
    final euAssets = allAssets.where((a) => a.category == AssetCategory.euStock).toList();
    expect(euAssets.length, greaterThanOrEqualTo(10));
    expect(euAssets.any((a) => a.symbol == 'MC.PA'), isTrue);
  });

  test('NativeWidgetService correctly filters stocks with variation > +1% for alerts', () {
    final now = DateTime.now();
    final model = StockWidgetModel(
      id: 'alert-test-widget',
      lastUpdated: now,
      items: [
        WidgetStockItem(
          id: '1',
          symbol: 'NVDA',
          customName: 'Nvidia',
          purchaseDate: now.subtract(const Duration(days: 10)),
          initialPrice: 100.0,
          currentPrice: 101.50, // +1.50% -> triggers notification
        ),
        WidgetStockItem(
          id: '2',
          symbol: 'AAPL',
          customName: 'Apple',
          purchaseDate: now.subtract(const Duration(days: 10)),
          initialPrice: 100.0,
          currentPrice: 101.00, // +1.00% -> exactly 1.0%, not > 1%
        ),
        WidgetStockItem(
          id: '3',
          symbol: 'TSLA',
          customName: 'Tesla',
          purchaseDate: now.subtract(const Duration(days: 10)),
          initialPrice: 100.0,
          currentPrice: 100.50, // +0.50% -> below threshold
        ),
        WidgetStockItem(
          id: '4',
          symbol: 'UBI.PA',
          customName: 'Ubisoft',
          purchaseDate: now.subtract(const Duration(days: 10)),
          initialPrice: 100.0,
          currentPrice: 95.00, // -5.00% -> negative variation
        ),
        WidgetStockItem(
          id: '5',
          symbol: 'BTC/EUR',
          customName: 'Bitcoin',
          purchaseDate: now.subtract(const Duration(days: 10)),
          initialPrice: 50000.0,
          currentPrice: 52000.0, // +4.00% -> triggers notification
        ),
      ],
    );

    final qualifying = NativeWidgetService().getItemsWithPositiveVariation(model, threshold: 1.0);
    expect(qualifying.length, 2);
    expect(qualifying.map((e) => e.symbol), containsAll(['NVDA', 'BTC/EUR']));
    expect(qualifying.map((e) => e.symbol), isNot(contains('AAPL')));
    expect(qualifying.map((e) => e.symbol), isNot(contains('TSLA')));
    expect(qualifying.map((e) => e.symbol), isNot(contains('UBI.PA')));
  });
}

