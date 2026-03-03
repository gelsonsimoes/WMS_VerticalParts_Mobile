import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class ManualInputWidget extends StatefulWidget {
  final Function(String) onSubmitted;
  final VoidCallback onCancel;

  const ManualInputWidget({
    super.key,
    required this.onSubmitted,
    required this.onCancel,
  });

  @override
  State<ManualInputWidget> createState() => _ManualInputWidgetState();
}

class _ManualInputWidgetState extends State<ManualInputWidget> {
  final TextEditingController _controller = TextEditingController();

  void _addChar(String char) {
    setState(() {
      _controller.text += char;
    });
  }

  void _backspace() {
    if (_controller.text.isNotEmpty) {
      setState(() {
        _controller.text = _controller.text.substring(0, _controller.text.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.darkBackground,
      padding: EdgeInsets.all(5.w),
      child: Column(
        children: [
          Text(
            'ENTRADA MANUAL',
            style: TextStyle(
              color: AppTheme.goldPrimary,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 3.h),
          TextField(
            controller: _controller,
            readOnly: true, // Forçamos o uso do nosso teclado industrial
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24.sp, color: AppTheme.textLight, letterSpacing: 4),
            decoration: InputDecoration(
              hintText: 'CÓDIGO',
              suffixIcon: IconButton(
                icon: const Icon(Icons.backspace, color: AppTheme.errorRed),
                onPressed: _backspace,
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 2.h,
              crossAxisSpacing: 2.w,
              childAspectRatio: 1.2,
              children: [
                ...['1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', '0', '-'].map((key) {
                  return ElevatedButton(
                    onPressed: () => _addChar(key),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.surfaceDark,
                      foregroundColor: AppTheme.textLight,
                    ),
                    child: Text(key, style: TextStyle(fontSize: 20.sp)),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.onCancel,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceDark),
                  child: const Text('CANCELAR'),
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => widget.onSubmitted(_controller.text),
                  child: const Text('CONFIRMAR'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
