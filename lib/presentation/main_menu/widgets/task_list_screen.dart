import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';
import 'package:verticalpartswms/theme/app_theme.dart';
import 'package:verticalpartswms/data/services/supabase_service.dart';
import 'package:verticalpartswms/data/models/task_model.dart';
import 'package:verticalpartswms/routes/app_routes.dart';

class TaskListScreen extends StatefulWidget {
  final String tipo; // 'alocacao' ou 'picking'

  const TaskListScreen({super.key, required this.tipo});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _isLoading = true;
  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    final tasks = await SupabaseService.getTarefas();
    setState(() {
      _tasks = tasks.where((t) => t.tipo.name == widget.tipo).toList();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.tipo == 'alocacao' ? 'TAREFAS DE ALOCAÇÃO' : 'TAREFAS DE PICKING',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: AppTheme.goldPrimary),
        ),
        backgroundColor: AppTheme.darkBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.goldPrimary),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
          : _tasks.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return _buildTaskCard(task);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 15.w, color: AppTheme.textMuted),
          SizedBox(height: 2.h),
          Text(
            'NENHUMA TAREFA PENDENTE',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12.sp, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: _loadTasks,
            child: const Text('ATUALIZAR', style: TextStyle(color: AppTheme.goldPrimary)),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Task task) {
    final item = task.itens.isNotEmpty ? task.itens.first : null;
    
    return Card(
      color: AppTheme.surfaceDark,
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: task.prioridade == 'Urgente' ? AppTheme.errorRed : AppTheme.goldPrimary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(4.w),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('TAREFA: #${task.id.toString().substring(0, 8)}', 
              style: TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold, fontSize: 11.sp)),
            _buildPriorityBadge(task.prioridade),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 1.h),
            Text(item?.sku ?? 'N/A', style: TextStyle(color: Colors.white, fontSize: 13.sp, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
            Text(item?.descricao ?? 'Sem descrição', style: TextStyle(color: AppTheme.textMuted, fontSize: 10.sp), maxLines: 1, overflow: TextOverflow.ellipsis),
            SizedBox(height: 1.h),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: AppTheme.goldPrimary),
                SizedBox(width: 1.w),
                Text(item?.endereco ?? 'N/A', style: const TextStyle(color: AppTheme.goldPrimary, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text('${item?.quantidadeEsperada ?? 0} UN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp)),
              ],
            ),
          ],
        ),
        onTap: () {
          if (widget.tipo == 'picking') {
            Navigator.pushNamed(context, AppRoutes.picking, arguments: task);
          } else {
            Navigator.pushNamed(context, AppRoutes.scanner, arguments: task);
          }
        },
      ),
    );
  }

  Widget _buildPriorityBadge(String prioridade) {
    Color color = AppTheme.textMuted;
    if (prioridade == 'Urgente') color = AppTheme.errorRed;
    if (prioridade == 'Alta') color = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), border: Border.all(color: color), borderRadius: BorderRadius.circular(4)),
      child: Text(prioridade.toUpperCase(), style: TextStyle(color: color, fontSize: 8.sp, fontWeight: FontWeight.bold)),
    );
  }
}
