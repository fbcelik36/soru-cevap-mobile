import 'package:flutter/material.dart';
import '../core/api_client.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.apiBaseUrl});
  final String apiBaseUrl;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _authorityName = TextEditingController();
  final _companyName = TextEditingController();
  final _companyAddress = TextEditingController();
  final _companyContact = TextEditingController();
  final _authorityContact = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _kvkk = false;
  bool _busy = false;

  Future<void> _submit() async {
    if (!_kvkk) {
      _err('KVKK onayı zorunludur.');
      return;
    }
    setState(() => _busy = true);
    try {
      final api = ApiClient(widget.apiBaseUrl);
      final res = await api.postJson('/auth/register', {
        'authority_name': _authorityName.text.trim(),
        'company_name': _companyName.text.trim(),
        'company_address': _companyAddress.text.trim(),
        'company_contact': _companyContact.text.trim(),
        'authority_contact': _authorityContact.text.trim(),
        'username': _username.text.trim(),
        'password': _password.text,
        'kvkk_accepted': true,
      });
      if (res['ok'] == true) {
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kayıt başarılı. Giriş yapabilirsiniz.')));
      } else {
        _err(res['error']?.toString() ?? 'Kayıt başarısız');
      }
    } catch (e) {
      _err('Bağlantı hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _err(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Üyelik')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _authorityName, decoration: const InputDecoration(labelText: 'Yetkili Kişi Ad-Soyad')),
            TextField(controller: _companyName, decoration: const InputDecoration(labelText: 'Firma Adı')),
            TextField(controller: _companyAddress, decoration: const InputDecoration(labelText: 'Firma Adres Bilgileri'), maxLines: 2),
            TextField(controller: _companyContact, decoration: const InputDecoration(labelText: 'Firma İletişim Bilgileri'), maxLines: 2),
            TextField(controller: _authorityContact, decoration: const InputDecoration(labelText: 'Yetkili Kişi İletişim Bilgileri'), maxLines: 2),
            TextField(controller: _username, decoration: const InputDecoration(labelText: 'Kullanıcı Adı')),
            TextField(controller: _password, decoration: const InputDecoration(labelText: 'Şifre (min 8)'), obscureText: true),
            const SizedBox(height: 12),
            const Align(alignment: Alignment.centerLeft, child: Text('KVKK Metni', style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 6),
            const Text('Kişisel verileriniz, soru–cevap hizmetinin yürütülmesi amacıyla işlenecektir.'),
            CheckboxListTile(
              value: _kvkk,
              onChanged: _busy ? null : (v) => setState(() => _kvkk = v ?? false),
              title: const Text('KVKK metnini okudum, kabul ediyorum.'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy ? const CircularProgressIndicator() : const Text('Kaydı Tamamla'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
