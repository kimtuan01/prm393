import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppSettingsProvider with ChangeNotifier {
  SharedPreferences? _prefs;
  bool _isLoading = true;
  bool _initialized = false;

  // Settings với giá trị mặc định
  String _language = 'vi';
  String _currency = 'VND';
  String _dateFormat = 'dd/MM/yyyy';
  String _firstDayOfWeek = 'Monday';
  String _firstDayOfMonth = '1';
  String _firstMonthOfYear = 'January';

  bool _showNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  // Getters
  bool get isLoading => _isLoading;
  bool get initialized => _initialized;
  String get language => _language;
  String get currency => _currency;
  String get dateFormat => _dateFormat;
  String get firstDayOfWeek => _firstDayOfWeek;
  String get firstDayOfMonth => _firstDayOfMonth;
  String get firstMonthOfYear => _firstMonthOfYear;
  bool get showNotifications => _showNotifications;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;

  // ✅ Constructor - khởi tạo async trong constructor
  AppSettingsProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _loadSettings();
      _initialized = true;
      _isLoading = false;
      notifyListeners();
      print('✅ AppSettingsProvider initialized successfully');
    } catch (e) {
      print('❌ Error initializing AppSettingsProvider: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _loadSettings() {
    if (_prefs == null) return;

    _language = _prefs!.getString('language') ?? 'vi';
    _currency = _prefs!.getString('currency') ?? 'VND';
    _dateFormat = _prefs!.getString('dateFormat') ?? 'dd/MM/yyyy';
    _firstDayOfWeek = _prefs!.getString('firstDayOfWeek') ?? 'Monday';
    _firstDayOfMonth = _prefs!.getString('firstDayOfMonth') ?? '1';
    _firstMonthOfYear = _prefs!.getString('firstMonthOfYear') ?? 'January';
    _showNotifications = _prefs!.getBool('showNotifications') ?? true;
    _soundEnabled = _prefs!.getBool('soundEnabled') ?? true;
    _vibrationEnabled = _prefs!.getBool('vibrationEnabled') ?? true;

    print('✅ Settings loaded: language=$_language, currency=$_currency');
  }

  // ✅ Setters với null check
  Future<void> setLanguage(String language) async {
    if (_prefs == null) {
      print('⚠️ SharedPreferences chưa sẵn sàng');
      return;
    }
    _language = language;
    await _prefs!.setString('language', language);
    print('🔔 Language changed to: $language');
    notifyListeners();
  }

  Future<void> setCurrency(String currency) async {
    if (_prefs == null) return;
    _currency = currency;
    await _prefs!.setString('currency', currency);
    notifyListeners();
  }

  Future<void> setDateFormat(String format) async {
    if (_prefs == null) return;
    _dateFormat = format;
    await _prefs!.setString('dateFormat', format);
    notifyListeners();
  }

  Future<void> setFirstDayOfWeek(String day) async {
    if (_prefs == null) return;
    _firstDayOfWeek = day;
    await _prefs!.setString('firstDayOfWeek', day);
    notifyListeners();
  }

  Future<void> setFirstDayOfMonth(String day) async {
    if (_prefs == null) return;
    _firstDayOfMonth = day;
    await _prefs!.setString('firstDayOfMonth', day);
    notifyListeners();
  }

  Future<void> setFirstMonthOfYear(String month) async {
    if (_prefs == null) return;
    _firstMonthOfYear = month;
    await _prefs!.setString('firstMonthOfYear', month);
    notifyListeners();
  }

  Future<void> setShowNotifications(bool value) async {
    if (_prefs == null) return;
    _showNotifications = value;
    await _prefs!.setBool('showNotifications', value);
    notifyListeners();
  }

  Future<void> setSoundEnabled(bool value) async {
    if (_prefs == null) return;
    _soundEnabled = value;
    await _prefs!.setBool('soundEnabled', value);
    notifyListeners();
  }

  Future<void> setVibrationEnabled(bool value) async {
    if (_prefs == null) return;
    _vibrationEnabled = value;
    await _prefs!.setBool('vibrationEnabled', value);
    notifyListeners();
  }
}
