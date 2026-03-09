import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class ReceivingProvider with ChangeNotifier {
  String? _nfe;
  String? _sku;
  String _quantity = "0";
  String _batch = "";
  String _expiry = "";
  String _weight = "";
  String _color = "";
  int _step = 1; // 1: NF, 2: Product, 3: Qty, 4: Extra
  bool _isLoading = false;

  int _totalItems = 0;
  int _checkedItems = 0;

  String? get nfe => _nfe;
  String? get sku => _sku;
  String get quantity => _quantity;
  String get batch => _batch;
  String get expiry => _expiry;
  String get weight => _weight;
  String get color => _color;
  int get step => _step;
  bool get isLoading => _isLoading;
  int get totalItems => _totalItems;
  int get checkedItems => _checkedItems;

  double get progress => _totalItems > 0 ? _checkedItems / _totalItems : 0;

  void startNF(String code) {
    _nfe = code;
    _totalItems = 10; // Mock de total de itens da NF
    _checkedItems = 0;
    _step = 2;
    notifyListeners();
  }

  void setProduct(String code) {
    _sku = code;
    _step = 3;
    notifyListeners();
  }

  void updateQuantity(String val) {
    _quantity = _quantity == "0" ? val : _quantity + val;
    notifyListeners();
  }

  void backspaceQuantity() {
    _quantity = _quantity.length > 1 ? _quantity.substring(0, _quantity.length - 1) : "0";
    notifyListeners();
  }

  void clearQuantity() {
    _quantity = "0";
    notifyListeners();
  }

  void nextToExtra() {
    _step = 4;
    notifyListeners();
  }

  void setBatch(String val) => _batch = val;
  void setExpiry(String val) => _expiry = val;
  void setWeight(String val) => _weight = val;
  void setColor(String val) => _color = val;

  Future<bool> finalizeItem() async {
    if (_nfe == null || _sku == null) return false;

    _isLoading = true;
    notifyListeners();

    try {
      final success = await SupabaseService.registrarRecebimento(
        nfe: _nfe!,
        sku: _sku!,
        quantidade: int.parse(_quantity),
        lote: _batch,
        validade: _expiry,
        peso: double.tryParse(_weight.replaceAll(',', '.')),
        cor: _color,
      );

      if (success) {
        _checkedItems++;
        _sku = null;
        _quantity = "0";
        _batch = "";
        _expiry = "";
        _weight = "";
        _color = "";
        _step = 2; // Volta para o próximo produto da mesma NF
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _nfe = null;
    _sku = null;
    _quantity = "0";
    _batch = "";
    _expiry = "";
    _weight = "";
    _color = "";
    _step = 1;
    _totalItems = 0;
    _checkedItems = 0;
    notifyListeners();
  }
}
