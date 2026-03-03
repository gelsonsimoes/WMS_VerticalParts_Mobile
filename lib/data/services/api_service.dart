import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import '../models/task_model.dart';

class ApiService {
  // Troque pelo IP do seu servidor backend quando ele estiver rodando
  static const String baseUrl = 'http://192.168.1.100:3000/api'; 
  final AuthProvider authProvider;

  ApiService(this.authProvider);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${authProvider.token}',
  };

  // 3.1 Listar Tarefas
  Future<List<Task>> getTasks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/tarefas?operador_id=${authProvider.user?.id}'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['tarefas'] as List)
            .map((t) => Task.fromJson(t))
            .toList();
      }
      return [];
    } catch (e) {
      print('Erro ao carregar tarefas: $e');
      return [];
    }
  }

  // 3.4 Registrar Coleta
  Future<bool> registerCollection(int tarefaId, int itemId, int qtd) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/coletas'),
        headers: _headers,
        body: json.encode({
          'tarefa_id': tarefaId,
          'item_id': itemId,
          'quantidade_coletada': qtd,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Erro ao registrar coleta: $e');
      return false; // Aqui entra a lógica de salvar offline se falhar
    }
  }

  // 3.3 Validar Código (Genérico)
  Future<Map<String, dynamic>?> validateBarcode(String codigo, String tipo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validar/codigo'),
        headers: _headers,
        body: json.encode({
          'tipo': tipo,
          'codigo': codigo,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
