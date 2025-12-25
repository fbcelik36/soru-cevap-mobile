import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import '../core/api_client.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, required this.apiBaseUrl});
  final String apiBaseUrl;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _busy = false;
  List<dynamic> _items = [];

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final api = ApiClient(widget.apiBaseUrl);
      final res = await api.getJson('/messages/my');
      if (res['ok'] == true) {
        _items = (res['items'] as List?) ?? [];
      } else {
        _err(res['error']?.toString() ?? 'Mesajlar alınamadı');
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

  Future<void> _sendToAdmin() async {
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
                TextField(controller: textCtrl, maxLines: 4, decoration: const InputDecoration(labelText: 'Mesaj')),
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
                        final res = await api.postMultipart('/messages/to-admin', {'message_text': textCtrl.text.trim()}, file);
                        if (res['ok'] == true) {
                          _err('Mesaj gönderildi');
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

  Future<void> _downloadAndOpen(String attachment) async {
    final filename = attachment.split('/').last;
    final dir = await getTemporaryDirectory();
    final savePath = '${dir.path}/$filename';
    try {
      final api = ApiClient(widget.apiBaseUrl);
      await api.downloadFile(filename, savePath);
      await OpenFilex.open(savePath);
    } catch (e) {
      _err('İndirme hatası: $e');
    }
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
              onPressed: _busy ? null : _sendToAdmin,
              icon: const Icon(Icons.send),
              label: const Text('Admin’e Mesaj'),
            ),
          ),
          const SizedBox(height: 10),
          if (_busy) const LinearProgressIndicator(),
          for (final it in _items)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (it['is_announcement'] == true)
                    const Text('DUYURU', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(it['message_text']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text('Tarih: ${it['created_at']}'),
                  if ((it['attachment'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _downloadAndOpen(it['attachment'].toString()),
                      icon: const Icon(Icons.download),
                      label: const Text('Eki indir/aç'),
                    ),
                  ]
                ]),
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
