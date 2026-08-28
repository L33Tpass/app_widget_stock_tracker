import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'screens/home_screen.dart';
import 'services/native_widget_service.dart';

/// Called in the background when user taps the refresh arrow on the phone home screen widget
@pragma("vm:entry-point")
Future<void> backgroundWidgetCallback(Uri? uri) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (uri?.host == 'refresh' || uri?.scheme == 'stocktracker') {
    await NativeWidgetService().refreshFromBackground();
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HomeWidget.registerInteractivityCallback(backgroundWidgetCallback);
  runApp(const StockTrackerApp());
}

class StockTrackerApp extends StatelessWidget {
  const StockTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stock Tracker Widget',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFEFEFEF),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF111827),
          primary: const Color(0xFF111827),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFEFEFEF),
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF111827)),
          titleTextStyle: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        fontFamily: null,
      ),
      home: const HomeScreen(),
    );
  }
}
