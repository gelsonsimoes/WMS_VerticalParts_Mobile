import 'package:flutter/material.dart';

class QuantityConfirmationProvider with ChangeNotifier {
  String _currentQuantity = "0";
  bool _isLoading = false;
  int _expectedQuantity = 0;

  String get currentQuantity => _currentQuantity;
  bool get isLoading => _isLoading;

  void init(int expected) {
    _expectedQuantity = expected;
    _currentQuantity = "0";
    _isLoading = false;
    notifyListeners();
  }

  void updateQuantity(String key) {
    if (_currentQuantity == "0") {
      _currentQuantity = key;
    } else {
      _currentQuantity += key;
    }
    notifyListeners();
  }

  void backspace() {
    if (_currentQuantity.length > 1) {
      _currentQuantity = _currentQuantity.substring(0, _currentQuantity.length - 1);
    } else {
      _currentQuantity = "0";
    }
    notifyListeners();
  }

  void clear() {
    _currentQuantity = "0";
    notifyListeners();
  }

  void quickAction(int value) {
    int current = int.tryParse(_currentQuantity) ?? 0;
    _currentQuantity = (current + value).clamp(0, 9999).toString();
    notifyListeners();
  }

  void setTotal() {
    _currentQuantity = _expectedQuantity.toString();
    notifyListeners();
  }

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
