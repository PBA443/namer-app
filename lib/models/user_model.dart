// lib/models/user_model.dart
class User {
  final int id;
  final String username;
  final String? email; // Nullable, depending on your DB
  final String token;

  User({
    required this.id,
    required this.username,
    this.email, // Make nullable if your DB email can be null
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'], // Will be null if key doesn't exist
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'email': email, 'token': token};
  }
}
