import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Email dan Password tidak boleh kosong!';
        _isLoading = false;
      });
      return;
    }

    final user = await _authService.signInWithEmailAndPassword(email, password);

    if (mounted) {
      setState(() => _isLoading = false);
      if (user == null) {
        setState(() => _errorMessage = 'Login Gagal. Periksa email dan password Anda.');
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Parkir ITS'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.car_crash, size: 80, color: Colors.blueAccent),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email ITS',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Login', style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterScreen()),
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Buat Akun Baru', style: TextStyle(fontSize: 16)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}