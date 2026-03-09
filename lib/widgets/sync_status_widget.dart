import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import '../theme/app_theme.dart';
import '../data/providers/sync_provider.dart';

class SyncStatusWidget extends StatelessWidget {
  const SyncStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final syncProvider = Provider.of<SyncProvider>(context);
    final bool isSyncing = syncProvider.isSyncing;
    final int pending = syncProvider.pendingCount;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: pending == 0 
            ? AppTheme.successGreen.withOpacity(0.1) 
            : AppTheme.goldPrimary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: pending == 0 ? AppTheme.successGreen : AppTheme.goldPrimary,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isSyncing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.goldPrimary),
            )
          else
            Icon(
              pending == 0 ? Icons.cloud_done : Icons.cloud_upload_rounded,
              color: pending == 0 ? AppTheme.successGreen : AppTheme.goldPrimary,
              size: 24,
            ),
          SizedBox(width: 3.w),
          Text(
            isSyncing 
                ? 'SINCRONIZANDO...' 
                : (pending == 0 ? 'SISTEMA SINCRONIZADO' : '$pending AÇÕES PENDENTES'),
            style: TextStyle(
              color: pending == 0 ? AppTheme.successGreen : AppTheme.goldPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}
