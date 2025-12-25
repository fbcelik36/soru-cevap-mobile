import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../core/api_client.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key, required this.apiBaseUrl});
  final String apiBaseUrl;

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  bool _busy = false;
  List<dynamic> _items = [];

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final api = ApiClient(widget.apiBaseUrl);
      final res = await api.getJson('/questions/my');
      if (res['ok'] == true) {
        _items = (res['items'] as List?) ?? [];
      } else {
        _err(res['error']?.toString() ?? 'Liste alınamadı');
      }
    } catch (e) {
      _err('Bağlantı hatası: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _err(String s) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _ask() async {
    final textCtrl = TextEditingController();
    File? file;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: StatefulBuilder(builder: (ctx2, setSt) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: textCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Soru Metni')),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(child: Text(file?.path.split('/').last ?? 'Dosya ekle (opsiyonel)')),
                  TextButton(
                    onPressed: () async {
                      final r = await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['pdf','doc','docx','jpg','jpeg','png'],
                      );
                      if (r != null && r.files.single.path != null) {
                        setSt(() => file = File(r.files.single.path!));
                      }
                    },
                    child: const Text('Seç'),
                  ),
                ]),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      setState(() => _busy = true);
                      try {
                        final api = ApiClient(widget.apiBaseUrl);
                        final res = await api.postMultipart('/questions', {'question_text': textCtrl.text.trim()}, file);
                        if (res['ok'] == true) {
                          _err('Soru gönderildi');
                          await _load();
                        } else {
                          _err(res['error']?.toString() ?? 'Gönderim başarısız');
                        }
                      } catch (e) {
                        _err('Bağlantı hatası: $e');
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
                    child: const Text('Gönder'),
                  ),
                ),
              ]),
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _ask,
              icon: const Icon(Icons.add),
              label: const Text('Soru Sor'),
            ),
          ),
          const SizedBox(height: 10),
          if (_busy) const LinearProgressIndicator(),
          for (final it in _items)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(it['question_text']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Durum: ${it['status']}  |  Tarih: ${it['created_at']}'),
                  if ((it['answer_text'] ?? '').toString().isNotEmpty) ...[
                    const Divider(),
                    Text('Cevap: ${it['answer_text']}'),
                  ],
                ]),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
