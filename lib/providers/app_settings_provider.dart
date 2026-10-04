import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider extends ChangeNotifier {
  static const String _darkModeKey = 'settings.dark_mode';
  static const String _languageCodeKey = 'settings.language_code';
  static const String _currencyCodeKey = 'settings.currency_code';
  static const String _dateFormatKey = 'settings.date_format';
  static const String _amountFormatKey = 'settings.amount_format';

  bool _isDarkMode = false;
  String _languageCode = 'fr';
  String _currencyCode = 'GNF';
  String _dateFormatPattern = 'dd/MM/yyyy';
  String _amountFormatPattern = '1 234 567,89';
  bool _isLoaded = false;

  AppSettingsProvider() {
    _load();
  }

  bool get isDarkMode => _isDarkMode;
  String get languageCode => _languageCode;
  bool get isFrench => _languageCode == 'fr';
  bool get isEnglish => _languageCode == 'en';
  bool get isLoaded => _isLoaded;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  Locale get locale => Locale(_languageCode);
  String get currencyCode => _currencyCode;
  String get dateFormatPattern => _dateFormatPattern;
  String get amountFormatPattern => _amountFormatPattern;
  String get numberLocale =>
      _amountFormatPattern == '1,234,567.89' ? 'en_US' : 'fr_FR';
  String get currencyLabel => _currencyCode == 'EUR' ? '€' : _currencyCode;

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
    final String savedLanguage = prefs.getString(_languageCodeKey) ?? 'fr';
    if (savedLanguage == 'fr' || savedLanguage == 'en') {
      _languageCode = savedLanguage;
    }

    final String savedCurrency =
        prefs.getString(_currencyCodeKey) ?? _currencyCode;
    if (<String>['GNF', 'FCFA', 'EUR'].contains(savedCurrency)) {
      _currencyCode = savedCurrency;
    }

    final String savedDateFormat =
        prefs.getString(_dateFormatKey) ?? _dateFormatPattern;
    if (<String>[
      'dd/MM/yyyy',
      'MM/dd/yyyy',
      'yyyy-MM-dd',
    ].contains(savedDateFormat)) {
      _dateFormatPattern = savedDateFormat;
    }

    final String savedAmountFormat =
        prefs.getString(_amountFormatKey) ?? _amountFormatPattern;
    if (<String>['1 234 567,89', '1,234,567.89'].contains(savedAmountFormat)) {
      _amountFormatPattern = savedAmountFormat;
    }

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) {
      return;
    }
    _isDarkMode = value;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  Future<void> setLanguageCode(String value) async {
    if (value != 'fr' && value != 'en') {
      return;
    }
    if (_languageCode == value) {
      return;
    }

    _languageCode = value;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, value);
  }

  Future<void> setCurrencyCode(String value) async {
    if (!<String>['GNF', 'FCFA', 'EUR'].contains(value)) {
      return;
    }
    if (_currencyCode == value) {
      return;
    }

    _currencyCode = value;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currencyCodeKey, value);
  }

  Future<void> setDateFormatPattern(String value) async {
    if (!<String>['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'].contains(value)) {
      return;
    }
    if (_dateFormatPattern == value) {
      return;
    }

    _dateFormatPattern = value;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dateFormatKey, value);
  }

  Future<void> setAmountFormatPattern(String value) async {
    if (!<String>['1 234 567,89', '1,234,567.89'].contains(value)) {
      return;
    }
    if (_amountFormatPattern == value) {
      return;
    }

    _amountFormatPattern = value;
    notifyListeners();

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_amountFormatKey, value);
  }

  String formatMoney(num value, {int decimals = 0, bool withCurrency = true}) {
    final NumberFormat formatter = NumberFormat.currency(
      locale: numberLocale,
      symbol: '',
      decimalDigits: decimals,
    );
    final String formatted = formatter.format(value).trim();
    if (!withCurrency) {
      return formatted;
    }
    return '$formatted $currencyLabel';
  }

  String formatDate(DateTime value) {
    return DateFormat(_dateFormatPattern, numberLocale).format(value);
  }

  String formatDateTime(DateTime value) {
    final String pattern = '$_dateFormatPattern HH:mm';
    return DateFormat(pattern, numberLocale).format(value);
  }
}
