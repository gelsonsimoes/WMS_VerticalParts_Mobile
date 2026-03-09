import 'package:flutter/material.dart';

class ReplenishmentProvider with ChangeNotifier {
  int _currentStep = 1; // 1: Source, 2: Product, 3: Qty, 4: Destination
  bool _isLoading = false;

  String? _sourceAddress;
  String? _sku;
  String _quantity = "0";
  String? _destinationAddress;

  // Getters
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get sourceAddress => _sourceAddress;
  String? get sku => _sku;
  String get quantity => _quantity;
  String? get destinationAddress => _destinationAddress;

  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void processScan(String code) {
    if (_isLoading) return;

    if (_currentStep == 1) {
      _sourceAddress = code;
      _currentStep = 2;
    } else if (_currentStep == 2) {
      _sku = code;
      _currentStep = 3;
    } else if (_currentStep == 4) {
      _destinationAddress = code;
      // The screen will handle the final call
    }
    notifyListeners();
  }

  void updateQuantity(String val) {
    if (_quantity == "0") {
      _quantity = val;
    } else {
      _quantity += val;
    }
    notifyListeners();
  }

  void backspaceQuantity() {
    if (_quantity.length > 1) {
      _quantity = _quantity.substring(0, _quantity.length - 1);
    } else {
      _quantity = "0";
    }
    notifyListeners();
  }

  void clearQuantity() {
    _quantity = "0";
    notifyListeners();
  }

  void nextToDestination() {
    _currentStep = 4;
    notifyListeners();
  }

  void setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void reset() {
    _currentStep = 1;
    _sourceAddress = null;
    _sku = null;
    _quantity = "0";
    _destinationAddress = null;
    _isLoading = false;
    notifyListeners();
  }
}
