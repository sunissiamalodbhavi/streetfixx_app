class User {
  final int id;
  final String role;
  final String name;

  User({
    required this.id,
    required this.role,
    this.name = '',
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      role: json['role'] ?? 'student',
      name: json['name'] ?? '',
    );
  }
}
