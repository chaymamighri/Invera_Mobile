enum UserRole {
  ADMIN,
  COMMERCIAL,
  RESPONSABLE_ACHAT
}

class User {
  final int id;
  final String email;
  final String nom;
  final String prenom;
  final UserRole role;
  final bool active;

  User({
    required this.id,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.role,
    required this.active,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      role: _parseRole(json['role']),
      active: json['active'] ?? true,
    );
  }

  static UserRole _parseRole(String? role) {
    if (role == null) return UserRole.COMMERCIAL;
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return UserRole.ADMIN;
      case 'RESPONSABLE_ACHAT':
        return UserRole.RESPONSABLE_ACHAT;
      default:
        return UserRole.COMMERCIAL;
    }
  }

  String get fullName => '$prenom $nom'.trim();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'nom': nom,
      'prenom': prenom,
      'role': role.name,
      'active': active,
    };
  }
}

// Réponse de login (correspond à JwtResponse du backend)
class LoginResponse {
  final String token;
  final int id;
  final String email;
  final String role;
  final String nom;
  final String prenom;

  LoginResponse({
    required this.token,
    required this.id,
    required this.email,
    required this.role,
    required this.nom,
    required this.prenom,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
    );
  }
}

// Pour les requêtes de login
class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

// Message response simple
class MessageResponse {
  final String message;

  MessageResponse({required this.message});

  factory MessageResponse.fromJson(Map<String, dynamic> json) {
    return MessageResponse(message: json['message'] ?? '');
  }
}