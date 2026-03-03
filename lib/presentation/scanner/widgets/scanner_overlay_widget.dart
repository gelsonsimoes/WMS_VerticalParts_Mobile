import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class ScannerOverlayWidget extends StatelessWidget {
  final Color borderColor;

  const ScannerOverlayWidget({
    super.key,
    this.borderColor = AppTheme.goldPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Sombreado ao redor do alvo
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.5),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 30.h,
                  width: 80.w,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Moldura do Alvo (Border)
        Align(
          alignment: Alignment.center,
          child: Container(
            height: 30.h,
            width: 80.w,
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 4),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _corner(0, 0),
                    _corner(0, 1),
                  ],
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _corner(1, 0),
                    _corner(1, 1),
                  ],
                ),
              ],
            ),
          ),
        ),
        // Texto de instrução
        Positioned(
          top: 55.h,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              color: Colors.black54,
              child: Text(
                'ALINHE O CÓDIGO NO CENTRO',
                style: TextStyle(
                  color: AppTheme.textLight,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _corner(double top, double left) {
    return const SizedBox.shrink(); // Apenas placeholder, a borda do container já faz o serviço
  }
}
