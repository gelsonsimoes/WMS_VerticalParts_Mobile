enum TaskType {
  recebimento,
  separacao,
  inventario,
  alocacao
}

class Task {
  final int id;
  final TaskType tipo;
  final String pedidoId;
  final List<TaskItem> itens;

  Task({
    required this.id,
    required this.tipo,
    required this.pedidoId,
    required this.itens,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      tipo: _parseType(json['tipo']),
      pedidoId: json['pedido_id'] ?? '',
      itens: (json['itens'] as List)
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
      default: return TaskType.separacao;
    }
  }
}

class TaskItem {
  final int sequencia;
  final String endereco;
  final String sku;
  final String descricao;
  final int quantidadeEsperada;
  int quantidadeColetada;
  final String codigoBarrasProduto;
  final String codigoBarrasEndereco;

  TaskItem({
    required this.sequencia,
    required this.endereco,
    required this.sku,
    required this.descricao,
    required this.quantidadeEsperada,
    this.quantidadeColetada = 0,
    required this.codigoBarrasProduto,
    required this.codigoBarrasEndereco,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      sequencia: json['sequencia'],
      endereco: json['endereco'],
      sku: json['sku'],
      descricao: json['descricao'],
      quantidadeEsperada: json['quantidade_esperada'],
      quantidadeColetada: json['quantidade_coletada'] ?? 0,
      codigoBarrasProduto: json['codigo_barras_produto'] ?? '',
      codigoBarrasEndereco: json['codigo_barras_endereco'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sequencia': sequencia,
      'quantidade_coletada': quantidadeColetada,
      'sku': sku,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
