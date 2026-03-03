class User {
  final int id;
  final String nome;
  final String perfil;

  User({
    required this.id,
    required this.nome,
    required this.perfil,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      nome: json['nome'],
      perfil: json['perfil'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'perfil': perfil,
    };
  }
}

class AuthResponse {
  final String token;
  final User usuario;

  AuthResponse({
    required this.token,
    required this.usuario,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      usuario: User.fromJson(json['usuario']),
    );
  }
}
