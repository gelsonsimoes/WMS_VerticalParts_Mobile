import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class TaskContextWidget extends StatelessWidget {
  final String operacao;
  final String itemEsperado;
  final int quantidade;
  final String? skuDescricao;

  const TaskContextWidget({
    super.key,
    required this.operacao,
    required this.itemEsperado,
    required this.quantidade,
    this.skuDescricao,
  });

  // Helper constructor for when we have a TaskItem
  factory TaskContextWidget.fromItem({
    required String operacao,
    required dynamic item, // Can be TaskItem or similar
  }) {
    return TaskContextWidget(
      operacao: operacao,
      itemEsperado: item.sku,
      quantidade: item.quantidadeEsperada,
      skuDescricao: item.descricao,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            'TAREFA ATUAL: ${operacao.toUpperCase()}',
            style: TextStyle(
              color: AppTheme.goldPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'ITEM: $itemEsperado',
            style: TextStyle(
              color: AppTheme.textLight,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (skuDescricao != null)
            Text(
              skuDescricao!,
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          SizedBox(height: 1.h),
          Text(
            'QTD. ESPERADA: $quantidade',
            style: TextStyle(
              color: AppTheme.successGreen,
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
