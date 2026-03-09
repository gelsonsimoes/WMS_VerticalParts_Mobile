enum TaskType {
  recebimento,
  separacao,
  inventario,
  alocacao,
  remanejamento
}

class Task {
  final String id; // Alterado para String (UUID)
  final TaskType tipo;
  final String status;
  final String prioridade;
  final String pedidoId;
  final List<TaskItem> itens;

  Task({
    required this.id,
    required this.tipo,
    required this.status,
    required this.prioridade,
    required this.pedidoId,
    required this.itens,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      tipo: _parseType(json['tipo']),
      status: json['status'] ?? 'pendente',
      prioridade: json['prioridade'] ?? 'Normal',
      pedidoId: json['pedido_id'] ?? '',
      itens: (json['itens'] as List? ?? [])
          .map((i) => TaskItem.fromJson(i))
          .toList(),
    );
  }

  static TaskType _parseType(String type) {
    switch (type.toLowerCase()) {
      case 'recebimento': return TaskType.recebimento;
      case 'separacao': return TaskType.separacao;
      case 'inventario': return TaskType.inventario;
      case 'alocacao': return TaskType.alocacao;
      case 'remanejamento': return TaskType.remanejamento;
      default: return TaskType.separacao;
    }
  }
}

class TaskItem {
  final String id; // UUID do item
  final int sequencia;
  final String endereco;
  final String sku;
  final String descricao;
  final int quantidadeEsperada;
  int quantidadeColetada;
  final String codigoBarrasProduto;
  final String codigoBarrasEndereco;
  final String status;

  TaskItem({
    required this.id,
    required this.sequencia,
    required this.endereco,
    required this.sku,
    required this.descricao,
    required this.quantidadeEsperada,
    this.quantidadeColetada = 0,
    required this.codigoBarrasProduto,
    required this.codigoBarrasEndereco,
    required this.status,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'],
      sequencia: json['sequencia'] ?? 0,
      endereco: json['endereco_id'] ?? '', // Mapeado de endereco_id
      sku: json['sku'] ?? '',
      descricao: json['descricao'] ?? '',
      quantidadeEsperada: json['quantidade_esperada'] ?? 0,
      quantidadeColetada: json['quantidade_coletada'] ?? 0,
      codigoBarrasProduto: json['codigo_barras_produto'] ?? '',
      codigoBarrasEndereco: json['codigo_barras_endereco'] ?? '',
      status: json['status'] ?? 'pendente',
    );
  }
}
