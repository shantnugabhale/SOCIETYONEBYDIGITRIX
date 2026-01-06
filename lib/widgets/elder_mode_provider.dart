import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Elder Mode Provider - Accessibility features
/// When enabled:
/// - No gradients
/// - No animations
/// - Larger text (1.2x)
/// - High contrast colors
/// - Simplified layouts
class ElderModeProvider extends ChangeNotifier {
  static const String _prefKey = 'elder_mode_enabled';
  bool _isEnabled = false;

  bool get isEnabled => _isEnabled;

  ElderModeProvider() {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_prefKey) ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isEnabled = !_isEnabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, _isEnabled);
    notifyListeners();
  }

  Future<void> setEnabled(bool enabled) async {
    if (_isEnabled == enabled) return;
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, _isEnabled);
    notifyListeners();
  }

  // Text scale factor for elder mode
  double get textScaleFactor => _isEnabled ? 1.2 : 1.0;

  // Check if animations should be disabled
  bool get disableAnimations => _isEnabled;
}

