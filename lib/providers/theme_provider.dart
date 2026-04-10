import 'package:flutter/material.dart';
import '../services/config_service.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  double _fontScale = 1.0;

  ThemeMode get themeMode => _themeMode;
  double get fontScale => _fontScale;

  void loadFromConfig() {
    final saved = ConfigService().get('theme_mode');
    switch (saved) {
      case 'light':
        _themeMode = ThemeMode.light;
      case 'dark':
        _themeMode = ThemeMode.dark;
      default:
        _themeMode = ThemeMode.system;
    }

    final scaleStr = ConfigService().get('font_scale');
    if (scaleStr != null) {
      _fontScale = (double.tryParse(scaleStr) ?? 1.0).clamp(0.8, 1.5);
    }
  }

  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    };
    ConfigService().set('theme_mode', value);
    notifyListeners();
  }

  void setFontScale(double scale) {
    final clamped = scale.clamp(0.8, 1.5);
    if (_fontScale == clamped) return;
    _fontScale = clamped;
    ConfigService().set('font_scale', clamped.toStringAsFixed(2));
    notifyListeners();
  }
}
