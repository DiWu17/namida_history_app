import 'package:flutter/material.dart';
import '../services/config_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('zh');

  Locale get locale => _locale;

  void loadFromConfig() {
    final saved = ConfigService().get('locale');
    if (saved != null && ['en', 'zh'].contains(saved)) {
      _locale = Locale(saved);
    }
  }

  void setLocale(Locale locale) {
    if (!['en', 'zh'].contains(locale.languageCode)) return;
    if (_locale == locale) return;

    _locale = locale;
    ConfigService().set('locale', locale.languageCode);
    notifyListeners();
  }

  void clearLocale() {
    _locale = const Locale('zh');
    ConfigService().set('locale', 'zh');
    notifyListeners();
  }
}
