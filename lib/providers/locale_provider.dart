import 'package:flutter/material.dart';
import '../services/config_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale? _locale;

  Locale? get locale => _locale;

  void loadFromConfig() {
    final saved = ConfigService().get('locale');
    if (saved != null && ['en', 'zh'].contains(saved)) {
      _locale = Locale(saved);
    }
    // If no saved locale, _locale remains null → uses device locale
  }

  void setLocale(Locale locale) {
    if (!['en', 'zh'].contains(locale.languageCode)) return;
    if (_locale == locale) return;

    _locale = locale;
    ConfigService().set('locale', locale.languageCode);
    notifyListeners();
  }

  void clearLocale() {
    _locale = null;
    ConfigService().remove('locale');
    notifyListeners();
  }
}
