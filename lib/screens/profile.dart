import 'package:flutter/material.dart';
import '../core/api_client.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.apiBaseUrl, required this.onLogout});
  final String apiBaseUrl;
  final Future<void> Function() onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _busy = false;
  Map<String, dynamic>? _user;

  final _authorityName = TextEditingController();
  final _companyName = TextEditingController();
  final _companyAddress = TextEditingController();
  final _companyContact = TextEditingController();
  final _authorityContact = TextEditingController();

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final api = ApiClient(widget.apiBaseUrl);
      final res = await api.getJson('/me');
      if (res['ok'] == true) {
        _user = (res['user'] as Map).cast<String, dynamic>();
        _authorityName.text = _user!['authority_name']?.toString() ?? '';
        _companyName.text = _user!['company_name']?.toString() ?? '';
        _companyAddress.text = _user!['company_address']?.toString() ?? '';
        _companyContact.text = _user!['company_contact']?.toString() ?? '';
        _authorityContact.text = _user!['authority_contact']?.toString() ?? '';
      } else {
        _err(res['error']?.toString() ?? 'Profil alınamadı');
      }
    } catch (e) {
      _err('Bağlantı hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final api = ApiClient(widget.apiBaseUrl);
      final res = await api.putJson('/me', {
        'authority_name': _authorityName.text.trim(),
        'company_name': _companyName.text.trim(),
        'company_address': _companyAddress.text.trim(),
        'company_contact': _companyContact.text.trim(),
        'authority_contact': _authorityContact.text.trim(),
      });
      if (res['ok'] == true) {
        _err('Kaydedildi');
      } else {
        _err(res['error']?.toString() ?? 'Kaydedilemedi');
      }
    } catch (e) {
      _err('Bağlantı hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _changePassword() async {
    final cur = TextEditingController();
    final nw = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Şifre Değiştir'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: cur, obscureText: true, decoration: const InputDecoration(labelText: 'Mevcut Şifre')),
            TextField(controller: nw, obscureText: true, decoration: const InputDecoration(labelText: 'Yeni Şifre (min 8)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Vazgeç')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() => _busy = true);
              try {
                final api = ApiClient(widget.apiBaseUrl);
                final res = await api.putJson('/me/password', {
                  'current_password': cur.text,
                  'new_password': nw.text,
                });
                if (res['ok'] == true) {
                  _err('Şifre güncellendi');
                } else {
                  _err(res['error']?.toString() ?? 'Şifre güncellenemedi');
                }
              } catch (e) {
                _err('Bağlantı hatası: $e');
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _err(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_busy) const LinearProgressIndicator(),
          TextField(controller: _authorityName, decoration: const InputDecoration(labelText: 'Yetkili Kişi Ad-Soyad')),
          TextField(controller: _companyName, decoration: const InputDecoration(labelText: 'Firma Adı')),
          TextField(controller: _companyAddress, maxLines: 2, decoration: const InputDecoration(labelText: 'Firma Adres Bilgileri')),
          TextField(controller: _companyContact, maxLines: 2, decoration: const InputDecoration(labelText: 'Firma İletişim Bilgileri')),
          TextField(controller: _authorityContact, maxLines: 2, decoration: const InputDecoration(labelText: 'Yetkili Kişi İletişim Bilgileri')),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _busy ? null : _save, child: const Text('Bilgileri Kaydet'))),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _busy ? null : _changePassword, child: const Text('Şifre Değiştir'))),
          const SizedBox(height: 8),
          SizedBox(width: double.infinity, child: TextButton(onPressed: _busy ? null : widget.onLogout, child: const Text('Çıkış'))),
        ],
      ),
    );
  }
}
