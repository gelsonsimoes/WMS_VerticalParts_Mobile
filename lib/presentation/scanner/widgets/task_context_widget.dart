import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class TaskContextWidget extends StatelessWidget {
  final String operacao;
  final String itemEsperado;
  final int quantidade;

  const TaskContextWidget({
    super.key,
    required this.operacao,
    required this.itemEsperado,
    required this.quantidade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: AppTheme.goldPrimary, width: 6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TAREFA ATUAL: $operacao',
            style: TextStyle(
              color: AppTheme.goldPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'ITEM: $itemEsperado',
            style: TextStyle(
              color: AppTheme.textLight,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'QTD. RESTANTE: $quantidade',
            style: TextStyle(
              color: AppTheme.successGreen,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
