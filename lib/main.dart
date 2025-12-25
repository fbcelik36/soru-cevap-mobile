import 'package:flutter/material.dart';
import 'core/auth_store.dart';
import 'screens/login.dart';
import 'screens/home.dart';

const String kDefaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://example.com/soru-cevap/api/v1',
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  Future<bool> _hasToken() async {
    final t = await AuthStore.readToken();
    return t != null && t.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Soru–Cevap',
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: ThemeMode.system,
      home: FutureBuilder<bool>(
        future: _hasToken(),
        builder: (context, snap) {
          if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          return snap.data! ? const HomeScreen(apiBaseUrl: kDefaultApiBaseUrl) : const LoginScreen(apiBaseUrl: kDefaultApiBaseUrl);
        },
      ),
    );
  }
}
