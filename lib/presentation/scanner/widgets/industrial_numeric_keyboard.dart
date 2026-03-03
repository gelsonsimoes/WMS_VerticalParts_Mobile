import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class IndustrialNumericKeyboard extends StatelessWidget {
  final Function(String) onKeyPressed;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  const IndustrialNumericKeyboard({
    super.key,
    required this.onKeyPressed,
    required this.onBackspace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRow(['1', '2', '3']),
        SizedBox(height: 1.h),
        _buildRow(['4', '5', '6']),
        SizedBox(height: 1.h),
        _buildRow(['7', '8', '9']),
        SizedBox(height: 1.h),
        _buildRow(['LIMPAR', '0', '⌫']),
      ],
    );
  }

  Widget _buildRow(List<String> keys) {
    return Expanded(
      child: Row(
        children: keys.map((key) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.w),
              child: _buildKey(key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKey(String label) {
    bool isAction = label == 'LIMPAR' || label == '⌫';
    
    return ElevatedButton(
      onPressed: () {
        if (label == '⌫') {
          onBackspace();
        } else if (label == 'LIMPAR') {
          onClear();
        } else {
          onKeyPressed(label);
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isAction ? AppTheme.surfaceDark : AppTheme.goldPrimary,
        foregroundColor: isAction ? AppTheme.goldPrimary : AppTheme.darkBackground,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: label.length > 1 ? 14.sp : 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
