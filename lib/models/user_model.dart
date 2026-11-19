class UserModel {
  final int id;
  final String name;
  final String email;
  final String? cedula;
  final String? telefono;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.cedula,
    this.telefono,
    this.roles = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json, {List<dynamic>? rolesJson}) {
    List<String> parsedRoles = [];
    if (rolesJson != null) {
      parsedRoles = rolesJson.map((e) => e.toString()).toList();
    } else if (json['roles'] != null && json['roles'] is List) {
      parsedRoles = (json['roles'] as List).map((e) {
        if (e is Map && e.containsKey('name')) return e['name'].toString();
        return e.toString();
      }).toList();
    }

    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      cedula: json['cedula']?.toString(),
      telefono: json['telefono']?.toString(),
      roles: parsedRoles,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'cedula': cedula,
    'telefono': telefono,
    'roles': roles,
  };

  bool get isOperator => roles.contains('operador');
  bool get isAdmin => roles.contains('administrador');
}
