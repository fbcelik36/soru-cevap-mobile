import 'package:flutter/material.dart';
import '../core/api_client.dart';
import '../core/auth_store.dart';
import 'home.dart';
import 'register.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.apiBaseUrl});
  final String apiBaseUrl;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _busy = false;

  Future<void> _login() async {
    setState(() => _busy = true);
    try {
      final api = ApiClient(widget.apiBaseUrl);
      final res = await api.postJson('/auth/login', {
        'username': _u.text.trim(),
        'password': _p.text,
      });
      if (res['ok'] == true) {
        await AuthStore.saveToken(res['token'] as String);
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => HomeScreen(apiBaseUrl: widget.apiBaseUrl)));
      } else {
        _err(res['error']?.toString() ?? 'Giriş başarısız');
      }
    } catch (e) {
      _err('Bağlantı hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _err(String s) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _u, decoration: const InputDecoration(labelText: 'Kullanıcı Adı')),
            const SizedBox(height: 12),
            TextField(controller: _p, decoration: const InputDecoration(labelText: 'Şifre'), obscureText: true),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _login,
                child: _busy ? const CircularProgressIndicator() : const Text('Giriş'),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RegisterScreen(apiBaseUrl: widget.apiBaseUrl))),
              child: const Text('Üye Ol'),
            ),
          ],
        ),
      ),
    );
  }
}
