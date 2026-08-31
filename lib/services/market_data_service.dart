import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/stock_asset.dart';
import '../models/stock_widget_model.dart';

class MarketDataService {
  static final MarketDataService _instance = MarketDataService._internal();
  factory MarketDataService() => _instance;
  MarketDataService._internal();

  double _latestEurUsdRate = 1.1620;
  DateTime? _lastRateFetch;

  // In-memory cache for live quotes: symbol -> price in EUR
  final Map<String, double> _livePriceCache = {};

  final List<StockAsset> _assets = [
    // Gaming & Entertainment Stocks
    const StockAsset(
      symbol: 'TTWO',
      name: 'Take-Two Interactive (GTA VI, 2K)',
      category: AssetCategory.gaming,
      currentPrice: 189.26,
      currency: '€',
      color: Color(0xFFE50914),
      icon: Icons.sports_esports,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'EA',
      name: 'Electronic Arts (EA Sports)',
      category: AssetCategory.gaming,
      currentPrice: 180.46,
      currency: '€',
      color: Color(0xFF001935),
      icon: Icons.videogame_asset,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'SONY',
      name: 'Sony Group Corp (PlayStation)',
      category: AssetCategory.gaming,
      currentPrice: 21.30,
      currency: '€',
      color: Color(0xFF003791),
      icon: Icons.gamepad,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'NTDOY',
      name: 'Nintendo Co., Ltd.',
      category: AssetCategory.gaming,
      currentPrice: 12.02,
      currency: '€',
      color: Color(0xFFE60012),
      icon: Icons.videogame_asset_outlined,
      exchange: 'OTC',
    ),
    const StockAsset(
      symbol: 'UBI.PA',
      name: 'Ubisoft Entertainment SA',
      category: AssetCategory.gaming,
      currentPrice: 5.05,
      currency: '€',
      color: Color(0xFF000000),
      icon: Icons.sports_esports,
      exchange: 'Euronext Paris',
    ),
    const StockAsset(
      symbol: 'CCOEY',
      name: 'Capcom Co., Ltd.',
      category: AssetCategory.gaming,
      currentPrice: 11.49,
      currency: '€',
      color: Color(0xFFFFCC00),
      icon: Icons.sports_esports,
      exchange: 'OTC',
    ),
    const StockAsset(
      symbol: 'RBLX',
      name: 'Roblox Corporation',
      category: AssetCategory.gaming,
      currentPrice: 35.08,
      currency: '€',
      color: Color(0xFF000000),
      icon: Icons.smart_toy,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'U',
      name: 'Unity Software Inc.',
      category: AssetCategory.gaming,
      currentPrice: 36.34,
      currency: '€',
      color: Color(0xFF222C37),
      icon: Icons.view_in_ar,
      exchange: 'NYSE',
    ),

    // Actions France & Europe (PEA / Euronext)
    const StockAsset(
      symbol: 'MC.PA',
      name: 'LVMH Moët Hennessy Louis Vuitton',
      category: AssetCategory.euStock,
      currentPrice: 453.30,
      currency: '€',
      color: Color(0xFF1B1B1B),
      icon: Icons.diamond_outlined,
      exchange: 'Euronext Paris',
    ),
    const StockAsset(
      symbol: 'TTE.PA',
      name: 'TotalEnergies SE',
      category: AssetCategory.euStock,
      currentPrice: 75.53,
      currency: '€',
      color: Color(0xFFED1C24),
      icon: Icons.local_gas_station,
      exchange: 'Euronext Paris',
    ),
    const StockAsset(
      symbol: 'SAN.PA',
      name: 'Sanofi SA',
      category: AssetCategory.euStock,
      currentPrice: 76.81,
      currency: '€',
      color: Color(0xFF5E2750),
      icon: Icons.health_and_safety,
      exchange: 'Euronext Paris',
    ),
    const StockAsset(
      symbol: 'OR.PA',
      name: "L'Oréal SA",
      category: AssetCategory.euStock,
      currentPrice: 384.70,
      currency: '€',
      color: Color(0xFFC00000),
      icon: Icons.brush,
      exchange: 'Euronext Paris',
    ),
    const StockAsset(
      symbol: 'AI.PA',
      name: 'Air Liquide SA',
      category: AssetCategory.euStock,
      currentPrice: 169.54,
      currency: '€',
      color: Color(0xFF0055A5),
      icon: Icons.air,
      exchange: 'Euronext Paris',
    ),
    const StockAsset(
      symbol: 'RMS.PA',
      name: 'Hermès International',
      category: AssetCategory.euStock,
      currentPrice: 1581.00,
      currency: '€',
      color: Color(0xFFF37021),
      icon: Icons.shopping_bag_outlined,
      exchange: 'Euronext Paris',
    ),
    const StockAsset(
      symbol: 'SU.PA',
      name: 'Schneider Electric SE',
      category: AssetCategory.euStock,
      currentPrice: 294.60,
      currency: '€',
      color: Color(0xFF009530),
      icon: Icons.electric_bolt,
      exchange: 'Euronext Paris',
    ),
    const StockAsset(
      symbol: 'AIR.PA',
      name: 'Airbus SE',
      category: AssetCategory.euStock,
      currentPrice: 197.24,
      currency: '€',
      color: Color(0xFF00205B),
      icon: Icons.flight,
      exchange: 'Euronext Paris',
    ),
    const StockAsset(
      symbol: 'BNP.PA',
      name: 'BNP Paribas SA',
      category: AssetCategory.euStock,
      currentPrice: 102.78,
      currency: '€',
      color: Color(0xFF00915A),
      icon: Icons.account_balance,
      exchange: 'Euronext Paris',
    ),
    const StockAsset(
      symbol: 'SAF.PA',
      name: 'Safran SA',
      category: AssetCategory.euStock,
      currentPrice: 337.00,
      currency: '€',
      color: Color(0xFF005AA9),
      icon: Icons.flight_takeoff,
      exchange: 'Euronext Paris',
    ),
    const StockAsset(
      symbol: 'CS.PA',
      name: 'AXA SA',
      category: AssetCategory.euStock,
      currentPrice: 43.10,
      currency: '€',
      color: Color(0xFF00008F),
      icon: Icons.security,
      exchange: 'Euronext Paris',
    ),
    const StockAsset(
      symbol: 'RACE',
      name: 'Ferrari N.V.',
      category: AssetCategory.euStock,
      currentPrice: 364.98,
      currency: '€',
      color: Color(0xFFD40000),
      icon: Icons.directions_car_filled,
      exchange: 'NYSE / Milan',
    ),
    const StockAsset(
      symbol: 'ASML.AS',
      name: 'ASML Holding NV',
      category: AssetCategory.euStock,
      currentPrice: 1451.80,
      currency: '€',
      color: Color(0xFF00386B),
      icon: Icons.developer_board,
      exchange: 'Euronext Amsterdam',
    ),
    const StockAsset(
      symbol: 'SAP.DE',
      name: 'SAP SE',
      category: AssetCategory.euStock,
      currentPrice: 190.90,
      currency: '€',
      color: Color(0xFF008FD3),
      icon: Icons.cloud,
      exchange: 'XETRA',
    ),

    // Top US Tech & Large Cap Stocks
    const StockAsset(
      symbol: 'AAPL',
      name: 'Apple Inc.',
      category: AssetCategory.usStock,
      currentPrice: 270.34,
      currency: '€',
      color: Color(0xFF555555),
      icon: Icons.apple,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'NVDA',
      name: 'NVIDIA Corporation',
      category: AssetCategory.usStock,
      currentPrice: 189.07,
      currency: '€',
      color: Color(0xFF76B900),
      icon: Icons.memory,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'MSFT',
      name: 'Microsoft Corp.',
      category: AssetCategory.usStock,
      currentPrice: 439.17,
      currency: '€',
      color: Color(0xFF00A4EF),
      icon: Icons.window,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'GOOGL',
      name: 'Alphabet (Google)',
      category: AssetCategory.usStock,
      currentPrice: 291.06,
      currency: '€',
      color: Color(0xFF4285F4),
      icon: Icons.search,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'AMZN',
      name: 'Amazon.com Inc.',
      category: AssetCategory.usStock,
      currentPrice: 224.67,
      currency: '€',
      color: Color(0xFFFF9900),
      icon: Icons.shopping_cart,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'META',
      name: 'Meta Platforms (Facebook)',
      category: AssetCategory.usStock,
      currentPrice: 491.54,
      currency: '€',
      color: Color(0xFF0668E1),
      icon: Icons.public,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'TSLA',
      name: 'Tesla Inc.',
      category: AssetCategory.usStock,
      currentPrice: 315.40,
      currency: '€',
      color: Color(0xFFE82127),
      icon: Icons.electric_car,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'PLTR',
      name: 'Palantir Technologies',
      category: AssetCategory.usStock,
      currentPrice: 159.97,
      currency: '€',
      color: Color(0xFF101114),
      icon: Icons.insights,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'AMD',
      name: 'Advanced Micro Devices',
      category: AssetCategory.usStock,
      currentPrice: 401.09,
      currency: '€',
      color: Color(0xFFED1C24),
      icon: Icons.hardware,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'INTC',
      name: 'Intel Corporation',
      category: AssetCategory.usStock,
      currentPrice: 77.00,
      currency: '€',
      color: Color(0xFF0071C5),
      icon: Icons.memory_outlined,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'QCOM',
      name: 'Qualcomm Inc.',
      category: AssetCategory.usStock,
      currentPrice: 144.50,
      currency: '€',
      color: Color(0xFF3253DC),
      icon: Icons.sensors,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'AVGO',
      name: 'Broadcom Inc.',
      category: AssetCategory.usStock,
      currentPrice: 317.46,
      currency: '€',
      color: Color(0xFFCC092F),
      icon: Icons.developer_board,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'ADBE',
      name: 'Adobe Inc.',
      category: AssetCategory.usStock,
      currentPrice: 251.02,
      currency: '€',
      color: Color(0xFFFF0000),
      icon: Icons.brush_outlined,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'CRM',
      name: 'Salesforce Inc.',
      category: AssetCategory.usStock,
      currentPrice: 225.00,
      currency: '€',
      color: Color(0xFF00A1E0),
      icon: Icons.cloud_done,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'ORCL',
      name: 'Oracle Corporation',
      category: AssetCategory.usStock,
      currentPrice: 128.62,
      currency: '€',
      color: Color(0xFFF80000),
      icon: Icons.storage,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'NFLX',
      name: 'Netflix Inc.',
      category: AssetCategory.usStock,
      currentPrice: 70.25,
      currency: '€',
      color: Color(0xFFE50914),
      icon: Icons.movie,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'SPOT',
      name: 'Spotify Technology SA',
      category: AssetCategory.usStock,
      currentPrice: 467.82,
      currency: '€',
      color: Color(0xFF1DB954),
      icon: Icons.music_note,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'COIN',
      name: 'Coinbase Global Inc.',
      category: AssetCategory.usStock,
      currentPrice: 156.99,
      currency: '€',
      color: Color(0xFF0052FF),
      icon: Icons.currency_exchange,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'ABNB',
      name: 'Airbnb Inc.',
      category: AssetCategory.usStock,
      currentPrice: 158.78,
      currency: '€',
      color: Color(0xFFFF5A5F),
      icon: Icons.holiday_village,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'UBER',
      name: 'Uber Technologies Inc.',
      category: AssetCategory.usStock,
      currentPrice: 65.59,
      currency: '€',
      color: Color(0xFF000000),
      icon: Icons.directions_car,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'BRK.B',
      name: 'Berkshire Hathaway Inc.',
      category: AssetCategory.usStock,
      currentPrice: 432.99,
      currency: '€',
      color: Color(0xFF1B365D),
      icon: Icons.account_balance,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'LLY',
      name: 'Eli Lilly and Company',
      category: AssetCategory.usStock,
      currentPrice: 997.66,
      currency: '€',
      color: Color(0xFFE31B23),
      icon: Icons.medication,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'JPM',
      name: 'JPMorgan Chase & Co.',
      category: AssetCategory.usStock,
      currentPrice: 306.09,
      currency: '€',
      color: Color(0xFF0F4C81),
      icon: Icons.account_balance,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'V',
      name: 'Visa Inc.',
      category: AssetCategory.usStock,
      currentPrice: 327.69,
      currency: '€',
      color: Color(0xFF1A1F71),
      icon: Icons.credit_card,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'MA',
      name: 'Mastercard Inc.',
      category: AssetCategory.usStock,
      currentPrice: 509.85,
      currency: '€',
      color: Color(0xFFFF5F00),
      icon: Icons.credit_card_outlined,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'WMT',
      name: 'Walmart Inc.',
      category: AssetCategory.usStock,
      currentPrice: 89.83,
      currency: '€',
      color: Color(0xFF0071CE),
      icon: Icons.storefront,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'COST',
      name: 'Costco Wholesale Corp.',
      category: AssetCategory.usStock,
      currentPrice: 814.90,
      currency: '€',
      color: Color(0xFF005EAA),
      icon: Icons.shopping_basket,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'DIS',
      name: 'Walt Disney Company',
      category: AssetCategory.usStock,
      currentPrice: 92.73,
      currency: '€',
      color: Color(0xFF113CCF),
      icon: Icons.castle,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'KO',
      name: 'Coca-Cola Company',
      category: AssetCategory.usStock,
      currentPrice: 76.75,
      currency: '€',
      color: Color(0xFFF40009),
      icon: Icons.local_drink,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'PEP',
      name: 'PepsiCo Inc.',
      category: AssetCategory.usStock,
      currentPrice: 120.74,
      currency: '€',
      color: Color(0xFF004B93),
      icon: Icons.fastfood,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: 'MCD',
      name: "McDonald's Corporation",
      category: AssetCategory.usStock,
      currentPrice: 228.37,
      currency: '€',
      color: Color(0xFFFFBC0D),
      icon: Icons.lunch_dining,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'NKE',
      name: 'NIKE Inc.',
      category: AssetCategory.usStock,
      currentPrice: 33.85,
      currency: '€',
      color: Color(0xFF111111),
      icon: Icons.snowshoeing,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'BA',
      name: 'Boeing Company',
      category: AssetCategory.usStock,
      currentPrice: 177.99,
      currency: '€',
      color: Color(0xFF0039A6),
      icon: Icons.airplanemode_active,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'CAT',
      name: 'Caterpillar Inc.',
      category: AssetCategory.usStock,
      currentPrice: 680.68,
      currency: '€',
      color: Color(0xFFFFCD11),
      icon: Icons.construction,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'XOM',
      name: 'Exxon Mobil Corporation',
      category: AssetCategory.usStock,
      currentPrice: 137.07,
      currency: '€',
      color: Color(0xFFEE1C25),
      icon: Icons.oil_barrel,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'PFE',
      name: 'Pfizer Inc.',
      category: AssetCategory.usStock,
      currentPrice: 24.35,
      currency: '€',
      color: Color(0xFF0093D0),
      icon: Icons.medical_services,
      exchange: 'NYSE',
    ),
    const StockAsset(
      symbol: 'NVO',
      name: 'Novo Nordisk A/S',
      category: AssetCategory.usStock,
      currentPrice: 39.20,
      currency: '€',
      color: Color(0xFF003366),
      icon: Icons.medication_liquid,
      exchange: 'NYSE',
    ),

    // Cryptomonnaies
    const StockAsset(
      symbol: 'BTC/EUR',
      name: 'Bitcoin / EUR',
      category: AssetCategory.crypto,
      currentPrice: 67649.98,
      currency: '€',
      color: Color(0xFFF7931A),
      icon: Icons.currency_bitcoin,
      exchange: 'Crypto',
    ),
    const StockAsset(
      symbol: 'ETH/EUR',
      name: 'Ethereum / EUR',
      category: AssetCategory.crypto,
      currentPrice: 2120.35,
      currency: '€',
      color: Color(0xFF627EEA),
      icon: Icons.toll,
      exchange: 'Crypto',
    ),
    const StockAsset(
      symbol: 'SOL/EUR',
      name: 'Solana / EUR',
      category: AssetCategory.crypto,
      currentPrice: 88.29,
      currency: '€',
      color: Color(0xFF14F195),
      icon: Icons.offline_bolt,
      exchange: 'Crypto',
    ),
    const StockAsset(
      symbol: 'XRP/EUR',
      name: 'Ripple / EUR',
      category: AssetCategory.crypto,
      currentPrice: 1.18,
      currency: '€',
      color: Color(0xFF23292F),
      icon: Icons.swap_horiz,
      exchange: 'Crypto',
    ),
    const StockAsset(
      symbol: 'BNB/EUR',
      name: 'Binance Coin / EUR',
      category: AssetCategory.crypto,
      currentPrice: 593.60,
      currency: '€',
      color: Color(0xFFF3BA2F),
      icon: Icons.account_balance_wallet,
      exchange: 'Crypto',
    ),
    const StockAsset(
      symbol: 'ADA/EUR',
      name: 'Cardano / EUR',
      category: AssetCategory.crypto,
      currentPrice: 0.17,
      currency: '€',
      color: Color(0xFF0033AD),
      icon: Icons.token,
      exchange: 'Crypto',
    ),
    const StockAsset(
      symbol: 'AVAX/EUR',
      name: 'Avalanche / EUR',
      category: AssetCategory.crypto,
      currentPrice: 6.20,
      currency: '€',
      color: Color(0xFFE84142),
      icon: Icons.terrain,
      exchange: 'Crypto',
    ),
    const StockAsset(
      symbol: 'DOGE/EUR',
      name: 'Dogecoin / EUR',
      category: AssetCategory.crypto,
      currentPrice: 0.07,
      currency: '€',
      color: Color(0xFFC2A633),
      icon: Icons.pets,
      exchange: 'Crypto',
    ),
    const StockAsset(
      symbol: 'DOT/EUR',
      name: 'Polkadot / EUR',
      category: AssetCategory.crypto,
      currentPrice: 0.71,
      currency: '€',
      color: Color(0xFFE6007A),
      icon: Icons.lens_blur,
      exchange: 'Crypto',
    ),
    const StockAsset(
      symbol: 'LINK/EUR',
      name: 'Chainlink / EUR',
      category: AssetCategory.crypto,
      currentPrice: 9.79,
      currency: '€',
      color: Color(0xFF375BD2),
      icon: Icons.link,
      exchange: 'Crypto',
    ),

    // Indices & Matières premières
    const StockAsset(
      symbol: 'SPY',
      name: 'SPDR S&P 500 ETF Trust',
      category: AssetCategory.marketIndex,
      currentPrice: 658.61,
      currency: '€',
      color: Color(0xFF1E88E5),
      icon: Icons.show_chart,
      exchange: 'NYSE Arca',
    ),
    const StockAsset(
      symbol: 'QQQ',
      name: 'Invesco QQQ Trust (Nasdaq 100)',
      category: AssetCategory.marketIndex,
      currentPrice: 614.33,
      currency: '€',
      color: Color(0xFF7B1FA2),
      icon: Icons.auto_graph,
      exchange: 'NASDAQ',
    ),
    const StockAsset(
      symbol: '^FCHI',
      name: 'Indice CAC 40 (Bourse de Paris)',
      category: AssetCategory.marketIndex,
      currentPrice: 8334.50,
      currency: '€',
      color: Color(0xFF0055A5),
      icon: Icons.stacked_line_chart,
      exchange: 'Euronext Paris',
    ),
    const StockAsset(
      symbol: '^GDAXI',
      name: 'Indice DAX 40 (Francfort)',
      category: AssetCategory.marketIndex,
      currentPrice: 26258.11,
      currency: '€',
      color: Color(0xFFFFCC00),
      icon: Icons.area_chart,
      exchange: 'XETRA',
    ),
    const StockAsset(
      symbol: 'DIA',
      name: 'SPDR Dow Jones Industrial Average',
      category: AssetCategory.marketIndex,
      currentPrice: 457.39,
      currency: '€',
      color: Color(0xFF0D47A1),
      icon: Icons.ssid_chart,
      exchange: 'NYSE Arca',
    ),
    const StockAsset(
      symbol: 'GC=F',
      name: 'Or (Gold / Once troy)',
      category: AssetCategory.marketIndex,
      currentPrice: 3858.61,
      currency: '€',
      color: Color(0xFFFFD700),
      icon: Icons.monetization_on,
      exchange: 'COMEX',
    ),
    const StockAsset(
      symbol: 'SLV',
      name: 'iShares Silver Trust (Argent)',
      category: AssetCategory.marketIndex,
      currentPrice: 51.59,
      currency: '€',
      color: Color(0xFFC0C0C0),
      icon: Icons.circle,
      exchange: 'NYSE Arca',
    ),
  ];

  List<StockAsset> getAllAssets() => List.unmodifiable(_assets);

  StockAsset? getAssetBySymbol(String symbol) {
    try {
      return _assets.firstWhere((a) => a.symbol.toUpperCase() == symbol.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  String _getYahooTicker(String symbol) {
    if (symbol.endsWith('/EUR')) {
      return '${symbol.split('/')[0]}-EUR';
    }
    if (symbol.endsWith('/USD')) {
      return '${symbol.split('/')[0]}-USD';
    }
    if (symbol == 'BRK.B') return 'BRK-B';
    if (symbol == 'BF.B') return 'BF-B';
    return symbol;
  }

  /// Fetches live EUR/USD exchange rate
  Future<double> getEurUsdRate() async {
    final now = DateTime.now();
    if (_lastRateFetch != null && now.difference(_lastRateFetch!).inMinutes < 15) {
      return _latestEurUsdRate;
    }

    try {
      final uri = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/EURUSD=X?interval=1d&range=1d');
      final res = await http.get(uri, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final meta = data['chart']['result'][0]['meta'];
        final rate = (meta['regularMarketPrice'] as num).toDouble();
        if (rate > 0.5 && rate < 2.0) {
          _latestEurUsdRate = rate;
          _lastRateFetch = now;
        }
      }
    } catch (_) {
      // Fallback to default
    }
    return _latestEurUsdRate;
  }

  /// Dynamic search on Yahoo Finance API for any stock, crypto, ETF, or commodity
  Future<List<StockAsset>> searchAssetsOnline(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    try {
      final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v1/finance/search?q=${Uri.encodeComponent(cleanQuery)}&quotesCount=10&newsCount=0',
      );
      final res = await http.get(uri, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final List quotes = data['quotes'] ?? [];
        final List<StockAsset> dynamicResults = [];

        for (final q in quotes) {
          final sym = q['symbol']?.toString();
          if (sym == null || sym.isEmpty) continue;

          final name = q['shortname']?.toString() ?? q['longname']?.toString() ?? sym;
          final quoteType = q['quoteType']?.toString().toUpperCase() ?? 'EQUITY';
          final exch = q['exchDisp']?.toString() ?? q['exchange']?.toString() ?? '';
          final industry = q['industry']?.toString().toLowerCase() ?? '';
          final sector = q['sector']?.toString().toLowerCase() ?? '';

          AssetCategory category = AssetCategory.usStock;
          IconData icon = Icons.business;
          Color color = const Color(0xFF4B5563);

          if (quoteType == 'CRYPTOCURRENCY' || sym.contains('-EUR') || sym.contains('-USD')) {
            category = AssetCategory.crypto;
            icon = Icons.currency_bitcoin;
            color = const Color(0xFFF7931A);
          } else if (industry.contains('gaming') ||
              industry.contains('game') ||
              sector.contains('entertainment') ||
              name.toLowerCase().contains('interactive') ||
              name.toLowerCase().contains('gaming')) {
            category = AssetCategory.gaming;
            icon = Icons.sports_esports;
            color = const Color(0xFF9333EA);
          } else if (sym.endsWith('.PA') ||
              sym.endsWith('.AS') ||
              sym.endsWith('.DE') ||
              sym.endsWith('.MI') ||
              exch.toLowerCase().contains('paris') ||
              exch.toLowerCase().contains('frankfurt') ||
              exch.toLowerCase().contains('amsterdam')) {
            category = AssetCategory.euStock;
            icon = Icons.euro_symbol;
            color = const Color(0xFF0284C7);
          } else if (quoteType == 'ETF' || quoteType == 'INDEX') {
            category = AssetCategory.marketIndex;
            icon = Icons.show_chart;
            color = const Color(0xFF2563EB);
          }

          // Check if already in catalog with known price
          final existing = getAssetBySymbol(sym);
          final price = existing?.currentPrice ?? 100.0;

          dynamicResults.add(
            StockAsset(
              symbol: sym,
              name: name,
              category: category,
              currentPrice: price,
              currency: '€',
              color: color,
              icon: icon,
              exchange: exch,
            ),
          );
        }

        return dynamicResults;
      }
    } catch (_) {
      // Return empty if offline or error
    }
    return [];
  }

  /// Fetches live real price in EUR for any symbol
  Future<double> fetchLivePriceInEur(String symbol) async {
    if (_livePriceCache.containsKey(symbol)) {
      return _livePriceCache[symbol]!;
    }

    final yahooSymbol = _getYahooTicker(symbol);
    try {
      final uri = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$yahooSymbol?interval=1d&range=1d');
      final res = await http.get(uri, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final meta = data['chart']['result'][0]['meta'];
        final rawPrice = (meta['regularMarketPrice'] as num).toDouble();
        final currency = meta['currency']?.toString().toUpperCase() ?? 'USD';

        double priceInEur = rawPrice;
        if (currency == 'USD') {
          final rate = await getEurUsdRate();
          priceInEur = rawPrice / rate;
        } else if (currency == 'GBP') {
          priceInEur = rawPrice * 1.16;
        } else if (currency == 'GBP' || currency == 'GBp') {
          priceInEur = (rawPrice / 100.0) * 1.16;
        }

        final rounded = double.parse(priceInEur.toStringAsFixed(2));
        _livePriceCache[symbol] = rounded;
        return rounded;
      }
    } catch (_) {
      // Fallback
    }

    // Fallback to asset catalogue price
    final asset = getAssetBySymbol(symbol);
    return asset?.currentPrice ?? 100.0;
  }

  /// Calculates or fetches the real historical price at [dateTime] in EUR
  Future<double> fetchHistoricalPriceInEur(String symbol, DateTime dateTime) async {
    final now = DateTime.now();
    final differenceInHours = now.difference(dateTime).inHours;
    if (differenceInHours <= 1) {
      return fetchLivePriceInEur(symbol);
    }

    final yahooSymbol = _getYahooTicker(symbol);
    final targetUtc = dateTime.toUtc();
    final epoch = targetUtc.millisecondsSinceEpoch ~/ 1000;
    final period1 = epoch - (86400 * 4); // 4 days before
    final period2 = epoch + (86400 * 4); // 4 days after

    try {
      final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/$yahooSymbol?period1=$period1&period2=$period2&interval=1d',
      );
      final res = await http.get(uri, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final result = data['chart']['result'][0];
        final meta = result['meta'];
        final List timestamps = result['timestamp'] ?? [];
        final List closes = result['indicators']?['quote']?[0]?['close'] ?? [];
        final currency = meta['currency']?.toString().toUpperCase() ?? 'USD';

        if (timestamps.isNotEmpty && closes.isNotEmpty) {
          int bestIdx = 0;
          int minDiff = ((timestamps[0] as int) - epoch).abs();

          for (int i = 1; i < timestamps.length; i++) {
            if (closes[i] == null) continue;
            final diff = ((timestamps[i] as int) - epoch).abs();
            if (diff < minDiff) {
              minDiff = diff;
              bestIdx = i;
            }
          }

          final closePrice = closes[bestIdx] != null ? (closes[bestIdx] as num).toDouble() : null;
          if (closePrice != null && closePrice > 0) {
            double priceInEur = closePrice;
            if (currency == 'USD') {
              final rate = await getEurUsdRate();
              priceInEur = closePrice / rate;
            } else if (currency == 'GBP' || currency == 'GBp') {
              priceInEur = (closePrice / 100.0) * 1.16;
            }
            return double.parse(priceInEur.toStringAsFixed(2));
          }
        }
      }
    } catch (_) {
      // Fallback to algorithmic approximation
    }

    return getFallbackHistoricalPrice(symbol, dateTime);
  }

  /// Synchronous fallback when offline
  double getFallbackHistoricalPrice(String symbol, DateTime dateTime) {
    final asset = getAssetBySymbol(symbol);
    final basePrice = asset?.currentPrice ?? 100.0;

    final now = DateTime.now();
    final differenceInHours = now.difference(dateTime).inHours;
    if (differenceInHours <= 0) return basePrice;

    final days = differenceInHours / 24.0;
    final seed = symbol.codeUnits.fold<int>(0, (p, c) => p + c) +
        dateTime.year * 10000 +
        dateTime.month * 100 +
        dateTime.day +
        dateTime.hour;
    final rng = Random(seed);

    // Realistic annual growth
    double annualGrowthRate = 0.12;
    if (symbol.contains('BTC') || symbol.contains('ETH') || symbol.contains('SOL')) {
      annualGrowthRate = 0.35;
    } else if (symbol == 'NVDA' || symbol == 'PLTR') {
      annualGrowthRate = 0.40;
    } else if (symbol == 'TTWO') {
      // Take-Two GTA VI anticipation model
      annualGrowthRate = 0.22;
    }

    final years = days / 365.25;
    double discountFactor = pow(1.0 + annualGrowthRate, years).toDouble();
    final cycle = sin(days / 30.0 * pi) * 0.05;
    final noise = (rng.nextDouble() - 0.5) * 0.03;

    double estimated = (basePrice / discountFactor) * (1.0 + cycle + noise);
    if (estimated < 1.0) estimated = basePrice * 0.1;
    return double.parse(estimated.toStringAsFixed(2));
  }

  void clearCache() {
    _livePriceCache.clear();
    _lastRateFetch = null;
  }

  /// Refreshes all prices in a widget from live real market API
  Future<void> refreshWidgetLivePrices(StockWidgetModel widgetModel) async {
    clearCache();
    for (var item in widgetModel.items) {
      try {
        final livePrice = await fetchLivePriceInEur(item.symbol);
        item.currentPrice = livePrice;
      } catch (_) {
        item.currentPrice = simulatePriceTick(item.symbol, item.currentPrice);
      }
    }
    widgetModel.lastUpdated = DateTime.now();
  }

  double simulatePriceTick(String symbol, double currentPrice) {
    final rng = Random();
    final deltaPct = (rng.nextDouble() - 0.48) * 0.006;
    final newPrice = currentPrice * (1.0 + deltaPct);
    return double.parse(newPrice.toStringAsFixed(2));
  }
}
