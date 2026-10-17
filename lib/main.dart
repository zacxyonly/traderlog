import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'constants/app_colors.dart';
import 'providers/trade_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/security_lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TradeProvider()),
      ],
      child: const TraderlogApp(),
    ),
  );
}

class TraderlogApp extends StatefulWidget {
  const TraderlogApp({super.key});

  @override
  State<TraderlogApp> createState() => _TraderlogAppState();
}

class _TraderlogAppState extends State<TraderlogApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      if (mounted) {
        context.read<TradeProvider>().lockApp();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TradeProvider>();

    return MaterialApp(
      title: 'Traderlog',
      debugShowCheckedModeBanner: false,
      themeMode: provider.settings.themeMode,

      // Light Theme
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBg,
        cardColor: AppColors.lightCard,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          secondary: AppColors.primaryDark,
          surface: AppColors.lightCard,
          error: AppColors.lose,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: AppColors.lightText),
        ),
      ),

      // Dark Theme (default and signature aesthetic)
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        cardColor: AppColors.darkCard,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.primaryLight,
          surface: AppColors.darkCard,
          error: AppColors.lose,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBg,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: AppColors.darkText),
        ),
      ),

      home: provider.isLocked
          ? const SecurityLockScreen()
          : const MainNavigationScreen(),
    );
  }
}
