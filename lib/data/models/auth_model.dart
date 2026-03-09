class OperadorPerfil {
  final String id;
  final String employeeId;
  final String nome;
  final String perfil;

  const OperadorPerfil({
    required this.id,
    required this.employeeId,
    required this.nome,
    required this.perfil,
  });

  factory OperadorPerfil.fromJson(Map<String, dynamic> json) => OperadorPerfil(
        id: json['id'],
        employeeId: json['employee_id'] ?? '',
        nome: json['nome'] ?? 'Operador',
        perfil: json['perfil'] ?? 'Geral',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'employee_id': employeeId,
        'nome': nome,
        'perfil': perfil,
      };
}
