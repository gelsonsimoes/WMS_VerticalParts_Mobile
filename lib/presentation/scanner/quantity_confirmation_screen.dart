import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../theme/app_theme.dart';
import './widgets/industrial_numeric_keyboard.dart';

class QuantityConfirmationScreen extends StatefulWidget {
  final String sku;
  final int expectedQuantity;

  const QuantityConfirmationScreen({
    super.key,
    required this.sku,
    required this.expectedQuantity,
  });

  @override
  State<QuantityConfirmationScreen> createState() => _QuantityConfirmationScreenState();
}

class _QuantityConfirmationScreenState extends State<QuantityConfirmationScreen> {
  String _currentQuantity = "0";
  bool _isLoading = false;

  void _updateQuantity(String key) {
    setState(() {
      if (_currentQuantity == "0") {
        _currentQuantity = key;
      } else {
        _currentQuantity += key;
      }
    });
  }

  void _backspace() {
    setState(() {
      if (_currentQuantity.length > 1) {
        _currentQuantity = _currentQuantity.substring(0, _currentQuantity.length - 1);
      } else {
        _currentQuantity = "0";
      }
    });
  }

  void _quickAction(int value) {
    int current = int.tryParse(_currentQuantity) ?? 0;
    setState(() {
      _currentQuantity = (current + value).clamp(0, 9999).toString();
    });
  }

  void _setTotal() {
    setState(() {
      _currentQuantity = widget.expectedQuantity.toString();
    });
  }

  Future<void> _confirmarQuantidade() async {
    int finalQty = int.tryParse(_currentQuantity) ?? 0;
    
    if (finalQty <= 0) {
      _showResult("QUANTIDADE INVÁLIDA", AppTheme.errorRed);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulação de Envio REST (Regra de Ouro: Sem banco local)
    await Future.delayed(const Duration(seconds: 1));

    if (finalQty > widget.expectedQuantity) {
      _showResult("ERRO: QUANTIDADE EXCEDE O LIMITE DA TAREFA", AppTheme.errorRed);
    } else {
      _showResult("QUANTIDADE REGISTRADA COM SUCESSO!", AppTheme.successGreen);
      if (mounted) {
        // Retorna para o scanner para o próximo item
        Navigator.pop(context, true);
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showResult(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CONFIRMAR QUANTIDADE'),
        backgroundColor: AppTheme.darkBackground,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(5.w),
          child: Column(
            children: [
              // Info Box
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(8),
                  border: const Border(left: BorderSide(color: AppTheme.goldPrimary, width: 6)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ITEM BIPADO', style: TextStyle(color: AppTheme.goldPrimary, fontSize: 11.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 0.5.h),
                    Text(widget.sku, style: TextStyle(color: AppTheme.textLight, fontSize: 16.sp, fontWeight: FontWeight.bold)),
                    SizedBox(height: 1.h),
                    Text('ESPERADO: ${widget.expectedQuantity} UN', style: TextStyle(color: AppTheme.textMuted, fontSize: 13.sp)),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              // Visualização da Qtd
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 2.h),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.goldPrimary, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _currentQuantity,
                    style: TextStyle(fontSize: 40.sp, fontWeight: FontWeight.bold, color: AppTheme.textLight),
                  ),
                ),
              ),

              SizedBox(height: 2.h),

              // Botões de Ação Rápida
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _quickActionBtn("-1", () => _quickAction(-1)),
                  _quickActionBtn("+1", () => _quickAction(1)),
                  _quickActionBtn("+5", () => _quickAction(5)),
                  _quickActionBtn("TOTAL", _setTotal, isGold: true),
                ],
              ),

              SizedBox(height: 2.h),

              // Teclado Industrial
              Expanded(
                child: IndustrialNumericKeyboard(
                  onKeyPressed: _updateQuantity,
                  onBackspace: _backspace,
                  onClear: () => setState(() => _currentQuantity = "0"),
                ),
              ),

              SizedBox(height: 2.h),

              // Botão de Confirmação Final
              SizedBox(
                width: double.infinity,
                height: 10.h,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmarQuantidade,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: AppTheme.darkBackground)
                    : Text('CONFIRMAR REGISTRO', style: TextStyle(fontSize: 18.sp)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickActionBtn(String label, VoidCallback onPressed, {bool isGold = false}) {
    return SizedBox(
      width: 20.w,
      height: 7.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: isGold ? AppTheme.goldPrimary : AppTheme.textMuted, width: 2),
          backgroundColor: isGold ? AppTheme.goldPrimary.withOpacity(0.1) : Colors.transparent,
          padding: EdgeInsets.zero,
        ),
        child: Text(label, style: TextStyle(color: isGold ? AppTheme.goldPrimary : AppTheme.textMuted, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
