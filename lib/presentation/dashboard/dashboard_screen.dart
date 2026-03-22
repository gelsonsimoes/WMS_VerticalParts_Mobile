import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _dados = {};

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    final client = Supabase.instance.client;
    try {
      final tarefasRes = await client
          .from('tarefas')
          .select('status')
          .inFilter('status', ['pendente', 'em_andamento', 'concluida']);

      final enderecos = await client
          .from('enderecos')
          .select('status, ativo')
          .eq('ativo', true);

      final operadores = await client
          .from('operadores')
          .select('status')
          .eq('status', 'Ativo');

      final List tarefas = tarefasRes as List;
      final List ends = enderecos as List;
      final List ops = operadores as List;

      final pendentes = tarefas.where((t) => t['status'] == 'pendente').length;
      final emAndamento = tarefas.where((t) => t['status'] == 'em_andamento').length;
      final concluidas = tarefas.where((t) => t['status'] == 'concluida').length;

      final disponiveis = ends.where((e) => e['status'] == 'Disponível').length;
      final ocupados = ends.where((e) => e['status'] == 'Ocupado').length;
      final totalEnds = ends.length;
      final ocupacaoPercent = totalEnds > 0 ? (ocupados / totalEnds * 100).round() : 0;

      setState(() {
        _dados = {
          'tarefas_pendentes': pendentes,
          'tarefas_em_andamento': emAndamento,
          'tarefas_concluidas': concluidas,
          'enderecos_disponiveis': disponiveis,
          'enderecos_ocupados': ocupados,
          'ocupacao_percent': ocupacaoPercent,
          'operadores_ativos': ops.length,
        };
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DASHBOARD'),
        backgroundColor: AppTheme.darkBackground,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.goldPrimary),
            onPressed: () { setState(() => _loading = true); _carregarDados(); },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.goldPrimary))
          : RefreshIndicator(
              onRefresh: _carregarDados,
              color: AppTheme.goldPrimary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('TAREFAS'),
                    SizedBox(height: 2.h),
                    Row(children: [
                      Expanded(child: _buildCard('PENDENTES', _dados['tarefas_pendentes'] ?? 0, AppTheme.goldPrimary, Icons.hourglass_empty_rounded)),
                      SizedBox(width: 3.w),
                      Expanded(child: _buildCard('EM ANDAMENTO', _dados['tarefas_em_andamento'] ?? 0, Colors.blue, Icons.play_circle_outline_rounded)),
                      SizedBox(width: 3.w),
                      Expanded(child: _buildCard('CONCLUÍDAS', _dados['tarefas_concluidas'] ?? 0, AppTheme.successGreen, Icons.check_circle_outline_rounded)),
                    ]),
                    SizedBox(height: 3.h),
                    _buildSectionTitle('OCUPAÇÃO DO ARMAZÉM'),
                    SizedBox(height: 2.h),
                    _buildOcupacaoCard(),
                    SizedBox(height: 3.h),
                    _buildSectionTitle('EQUIPE'),
                    SizedBox(height: 2.h),
                    _buildCard('OPERADORES ATIVOS', _dados['operadores_ativos'] ?? 0, AppTheme.successGreen, Icons.people_rounded, fullWidth: true),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(children: [
      Container(width: 4, height: 20, color: AppTheme.goldPrimary,
          margin: const EdgeInsets.only(right: 8)),
      Text(title, style: TextStyle(color: AppTheme.goldPrimary,
          fontSize: 11.sp, fontWeight: FontWeight.bold, letterSpacing: 2)),
    ]);
  }

  Widget _buildCard(String label, int valor, Color cor, IconData icon, {bool fullWidth = false}) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: cor, size: 24),
        SizedBox(height: 1.h),
        Text('$valor', style: TextStyle(color: cor, fontSize: 24.sp, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 8.sp, letterSpacing: 1)),
      ]),
    );
  }

  Widget _buildOcupacaoCard() {
    final percent = _dados['ocupacao_percent'] ?? 0;
    final disponiveis = _dados['enderecos_disponiveis'] ?? 0;
    final ocupados = _dados['enderecos_ocupados'] ?? 0;
    final cor = percent > 80 ? AppTheme.errorRed : percent > 60 ? AppTheme.goldPrimary : AppTheme.successGreen;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cor.withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$percent%', style: TextStyle(color: cor, fontSize: 22.sp, fontWeight: FontWeight.bold)),
          Row(children: [
            _buildLegenda('LIVRE', disponiveis, AppTheme.successGreen),
            SizedBox(width: 4.w),
            _buildLegenda('OCUPADO', ocupados, AppTheme.errorRed),
          ]),
        ]),
        SizedBox(height: 1.5.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: AppTheme.darkBackground,
            color: cor,
            minHeight: 12,
          ),
        ),
        SizedBox(height: 1.h),
        Text('ENDEREÇOS DO ARMAZÉM', style: TextStyle(color: AppTheme.textMuted, fontSize: 9.sp, letterSpacing: 1)),
      ]),
    );
  }

  Widget _buildLegenda(String label, int valor, Color cor) {
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text('$valor', style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 12.sp)),
      Text(label, style: TextStyle(color: AppTheme.textMuted, fontSize: 8.sp)),
    ]);
  }
}
