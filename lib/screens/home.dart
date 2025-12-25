import 'package:flutter/material.dart';
import '../core/auth_store.dart';
import '../core/api_client.dart';
import 'login.dart';
import 'questions.dart';
import 'messages.dart';
import 'profile.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.apiBaseUrl});
  final String apiBaseUrl;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _i = 0;

  Future<void> _logout() async {
    try {
      await ApiClient(widget.apiBaseUrl).postJson('/auth/logout', {});
    } catch (_) {}
    await AuthStore.clear();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(apiBaseUrl: widget.apiBaseUrl)),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      QuestionsScreen(apiBaseUrl: widget.apiBaseUrl),
      MessagesScreen(apiBaseUrl: widget.apiBaseUrl),
      ProfileScreen(apiBaseUrl: widget.apiBaseUrl, onLogout: _logout),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soru–Cevap'),
        actions: [
          IconButton(onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: tabs[_i],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.help_outline), label: 'Sorular'),
          NavigationDestination(icon: Icon(Icons.message_outlined), label: 'Mesajlar'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}
