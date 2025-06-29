// lib/services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart'; // Import your User model

class AuthService {
  final String baseUrl; // Base URL from MyAppState

  AuthService(this.baseUrl);

  static const _userKey = 'currentUser';

  Future<User> register({
    required String username,
    required String password,
    required String email,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'email': email, // Ensure your backend accepts email
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final user = User.fromJson(json.decode(response.body));
      await _saveUser(user);
      return user;
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to register');
    }
  }

  Future<User> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final user = User.fromJson(json.decode(response.body));
      await _saveUser(user);
      return user;
    } else {
      final errorBody = json.decode(response.body);
      throw Exception(errorBody['message'] ?? 'Failed to log in');
    }
  }

  Future<void> logout() async {
    await _clearUser();
  }

  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return User.fromJson(json.decode(userJson));
    }
    return null;
  }

  Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, json.encode(user.toJson()));
  }

  Future<void> _clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}
