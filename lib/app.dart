import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';

import 'providers/auth_provider.dart';
import 'providers/app_settings_provider.dart';
import 'providers/clients_provider.dart';
import 'providers/expenses_provider.dart';
import 'providers/products_provider.dart';
import 'providers/sales_provider.dart';
import 'providers/suppliers_provider.dart';
import 'screens/firebase_setup_screen.dart';
import 'screens/splash_screen.dart';

class BoutiqueApp extends StatelessWidget {
  const BoutiqueApp({
    super.key,
    required this.firebaseReady,
    this.firebaseError,
  });

  final bool firebaseReady;
  final Object? firebaseError;

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF4F46E5); // Indigo 600
    const Color bgColor = Color(0xFFF8FAFC); // Slate 50
    final TextTheme interBaseTextTheme = GoogleFonts.interTextTheme(
      Theme.of(context).textTheme,
    );
    final TextTheme premiumTextTheme = interBaseTextTheme.copyWith(
      displayLarge: GoogleFonts.poppins(
        textStyle: interBaseTextTheme.displayLarge,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
      ),
      displayMedium: GoogleFonts.poppins(
        textStyle: interBaseTextTheme.displayMedium,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
      ),
      displaySmall: GoogleFonts.poppins(
        textStyle: interBaseTextTheme.displaySmall,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF0F172A),
      ),
      headlineLarge: GoogleFonts.poppins(
        textStyle: interBaseTextTheme.headlineLarge,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      headlineMedium: GoogleFonts.poppins(
        textStyle: interBaseTextTheme.headlineMedium,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      headlineSmall: GoogleFonts.poppins(
        textStyle: interBaseTextTheme.headlineSmall,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      titleLarge: GoogleFonts.poppins(
        textStyle: interBaseTextTheme.titleLarge,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      titleMedium: GoogleFonts.poppins(
        textStyle: interBaseTextTheme.titleMedium,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      titleSmall: GoogleFonts.poppins(
        textStyle: interBaseTextTheme.titleSmall,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      labelLarge: GoogleFonts.poppins(
        textStyle: interBaseTextTheme.labelLarge,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF0F172A),
      ),
      labelMedium: GoogleFonts.inter(
        textStyle: interBaseTextTheme.labelMedium,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF64748B),
      ),
      labelSmall: GoogleFonts.inter(
        textStyle: interBaseTextTheme.labelSmall,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF64748B),
      ),
      bodyLarge: GoogleFonts.inter(
        textStyle: interBaseTextTheme.bodyLarge,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF334155),
      ),
      bodyMedium: GoogleFonts.inter(
        textStyle: interBaseTextTheme.bodyMedium,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF475569),
      ),
      bodySmall: GoogleFonts.inter(
        textStyle: interBaseTextTheme.bodySmall,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF64748B),
      ),
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: bgColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        surface: Colors.white,
      ),
      textTheme: premiumTextTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: bgColor,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0F172A),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF0F172A),
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF0B1020),
      textTheme: premiumTextTheme.apply(
        bodyColor: const Color(0xFFE2E8F0),
        displayColor: const Color(0xFFE2E8F0),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Color(0xFF0B1020),
        foregroundColor: Color(0xFFE2E8F0),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF111827),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF111827),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF334155)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    Widget buildMaterialApp(ThemeMode themeMode, Locale locale) {
      return MaterialApp(
        onGenerateTitle: (BuildContext context) =>
            AppLocalizations.of(context)?.appName ?? 'Gestion Boutique GN',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        locale: locale,
        supportedLocales: const <Locale>[Locale('fr'), Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: firebaseReady
            ? const SplashScreen()
            : FirebaseSetupScreen(error: firebaseError),
      );
    }

    if (!firebaseReady) {
      return ChangeNotifierProvider<AppSettingsProvider>(
        create: (_) => AppSettingsProvider(),
        child: Consumer<AppSettingsProvider>(
          builder: (BuildContext context, AppSettingsProvider settings, _) {
            return buildMaterialApp(settings.themeMode, settings.locale);
          },
        ),
      );
    }

    return MultiProvider(
      providers: <ChangeNotifierProvider<dynamic>>[
        ChangeNotifierProvider<AppSettingsProvider>(
          create: (_) => AppSettingsProvider(),
        ),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<ProductsProvider>(
          create: (BuildContext context) =>
              ProductsProvider(authProvider: context.read<AuthProvider>()),
        ),
        ChangeNotifierProvider<ClientsProvider>(
          create: (BuildContext context) =>
              ClientsProvider(authProvider: context.read<AuthProvider>()),
        ),
        ChangeNotifierProvider<SalesProvider>(
          create: (BuildContext context) =>
              SalesProvider(authProvider: context.read<AuthProvider>()),
        ),
        ChangeNotifierProvider<ExpensesProvider>(
          create: (BuildContext context) =>
              ExpensesProvider(authProvider: context.read<AuthProvider>()),
        ),
        ChangeNotifierProvider<SuppliersProvider>(
          create: (BuildContext context) =>
              SuppliersProvider(authProvider: context.read<AuthProvider>()),
        ),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (BuildContext context, AppSettingsProvider settings, _) {
          return buildMaterialApp(settings.themeMode, settings.locale);
        },
      ),
    );
  }
}
