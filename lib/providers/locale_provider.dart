import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('zh');

  Locale get locale => _locale;

  void setLocale(Locale locale) {
    if (!['en', 'zh'].contains(locale.languageCode)) return;
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();
  }

  void clearLocale() {
    _locale = const Locale('zh');
    notifyListeners();
  }
}
