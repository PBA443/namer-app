// lib/screens/login_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Assuming MyAppState is in main.dart
import 'register_page.dart'; // To navigate to register page

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<MyAppState>(context, listen: false);
      await appState.login(_usernameController.text, _passwordController.text);

      // --- Moved setState for success case here ---
      if (!mounted) return; // Guard against context use across async gap
      setState(() {
        _isLoading = false; // Reset loading on success
        _errorMessage = null; // Clear error on success
      });
      // --- End of moved setState ---

      // After successful login, the Consumer in MyApp will handle navigation
      // so you generally don't need Navigator.pop(context) here if MyApp
      // is correctly set up to redirect based on appState.currentUser.
    } catch (e) {
      // --- Moved setState for error case here ---
      if (!mounted) return; // Guard against context use across async gap
      setState(() {
        _errorMessage = e.toString().replaceFirst(
          'Exception: ',
          '',
        ); // Clean up error message
        _isLoading = false; // Reset loading on error
      });
      // --- End of moved setState ---
    }
    // The 'finally' block is now implicitly handled by setting _isLoading=false in both try and catch.
    // If there were other cleanup operations that MUST run regardless of success/error
    // (e.g., closing a stream, disposing a local object not related to setState),
    // then 'finally' would still be used for those specific operations,
    // but without any setState or return.
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _login,
                      child: const Text('Login'),
                    ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const RegisterPage(),
                    ),
                  );
                },
                child: const Text('Don\'t have an account? Register here.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
