import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';
import 'screens/home_screen.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'services/config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ConfigService().init();

  final localeProvider = LocaleProvider();
  localeProvider.loadFromConfig();

  final themeProvider = ThemeProvider();
  themeProvider.loadFromConfig();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => localeProvider),
        ChangeNotifierProvider(create: (_) => themeProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static ThemeData _buildTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final seedColor = isDark ? const Color(0xFF4e4c72) : const Color(0xFF9c99c1);

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: isDark
            ? Color.alphaBlend(seedColor.withAlpha(15), colorScheme.surface)
            : Color.alphaBlend(seedColor.withAlpha(25), Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: isDark
            ? Color.alphaBlend(seedColor.withAlpha(35), const Color(0xFF141414))
            : Color.alphaBlend(seedColor.withAlpha(35), Colors.white),
      ),
      scaffoldBackgroundColor: isDark
          ? colorScheme.surface
          : Color.alphaBlend(seedColor.withAlpha(12), Colors.white),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withAlpha(40),
        thickness: 0.5,
      ),
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      textTheme: TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
        titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: colorScheme.onSurface),
        titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: colorScheme.onSurface.withAlpha(isDark ? 210 : 200)),
        titleSmall: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: colorScheme.onSurface.withAlpha(isDark ? 180 : 160)),
        bodyMedium: TextStyle(fontSize: 14, color: colorScheme.onSurface.withAlpha(isDark ? 200 : 180)),
        bodySmall: TextStyle(fontSize: 13, color: colorScheme.onSurface.withAlpha(isDark ? 170 : 140)),
        labelMedium: TextStyle(fontWeight: FontWeight.w500, fontSize: 12, color: colorScheme.onSurfaceVariant),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<LocaleProvider, ThemeProvider>(
      builder: (context, localeProvider, themeProvider, child) {
        return MaterialApp(
          title: 'Namida Charts',
          locale: localeProvider.locale,
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            if (localeProvider.locale != null) return localeProvider.locale;
            for (var locale in supportedLocales) {
              if (locale.languageCode == deviceLocale?.languageCode) {
                return locale;
              }
            }
            return supportedLocales.first;
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          theme: _buildTheme(Brightness.light),
          darkTheme: _buildTheme(Brightness.dark),
          themeMode: themeProvider.themeMode,
          home: const AnalyzerHome(),
        );
      },
    );
  }
}
