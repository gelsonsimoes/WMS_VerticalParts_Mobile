import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../theme/app_theme.dart';

class SyncStatusWidget extends StatelessWidget {
  final bool isOnline;

  const SyncStatusWidget({super.key, this.isOnline = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: isOnline 
            ? AppTheme.successGreen.withOpacity(0.1) 
            : AppTheme.errorRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOnline ? AppTheme.successGreen : AppTheme.errorRed,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: isOnline ? AppTheme.successGreen : AppTheme.errorRed,
            size: 24,
          ),
          SizedBox(width: 3.w),
          Text(
            isOnline ? 'SISTEMA ONLINE' : 'ERRO DE CONEXÃO',
            style: TextStyle(
              color: isOnline ? AppTheme.successGreen : AppTheme.errorRed,
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}
