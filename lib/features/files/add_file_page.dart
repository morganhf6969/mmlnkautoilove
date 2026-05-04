import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/file_service.dart';
import '../../data/models/saved_item.dart';
import '../../data/repositories/saved_item_repository.dart';

class AddFilePage extends StatefulWidget {
  final String category;
  final bool isPremium;

  const AddFilePage({
    super.key,
    required this.category,
    this.isPremium = false,
  });

  @override
  State<AddFilePage> createState() => _AddFilePageState();
}

class _AddFilePageState extends State<AddFilePage> {
  final SavedItemRepository _repo = SavedItemRepository();
  final TextEditingController _hashtagController = TextEditingController();
  bool _formattingHashtags = false;

  String? _selectedFilePath;
  String? _selectedFileName;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _hashtagController.addListener(_formatHashtags);
  }

  void _formatHashtags() {
    if (_formattingHashtags) return;
    _formattingHashtags = true;

    String text = _hashtagController.text;

    // Aggiunge '#' alla prima parola non appena si inizia a digitare
    if (text.isNotEmpty && !text.startsWith('#')) {
      text = '#$text';
      _hashtagController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      _formattingHashtags = false;
      return;
    }

    // Alla pressione dello spazio: chiude il tag corrente e prepara il prossimo con '#'
    if (text.endsWith(' ')) {
      final trimmed = text.trim();
      if (trimmed.isNotEmpty && !trimmed.endsWith(',')) {
        text = '$trimmed, #';
        _hashtagController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    }

    _formattingHashtags = false;
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: false);
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFilePath = result.files.single.path;
        _selectedFileName = result.files.single.name;
      });
    }
  }

  Future<void> _save() async {
    if (_selectedFilePath == null) return;
    setState(() => _saving = true);

    try {
      final localPath = await FileService.copyToApp(_selectedFilePath!);
      final hashtags = _hashtagController.text
          .split(RegExp(r'[\s,]+'))
          .map((t) => t.replaceAll('#', '').trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final item = SavedItem(
        url: localPath,
        platform: 'file',
        category: widget.category,
        hashtags: hashtags,
        createdAt: DateTime.now(),
        ogTitle: _selectedFileName,
        ogImage: null,
      );

      await _repo.save(item, isPremium: widget.isPremium);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _hashtagController.removeListener(_formatHashtags);
    _hashtagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Aggiungi file',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selettore file
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedFilePath != null
                        ? Colors.blue.shade300
                        : Colors.grey.shade200,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      _selectedFilePath != null
                          ? FileService.iconForPath(_selectedFilePath!)
                          : '📎',
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedFileName ?? 'Tocca per selezionare un file',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: _selectedFilePath != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: _selectedFilePath != null
                            ? Colors.black87
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Hashtag
            const Text('Hashtag',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            TextField(
              controller: _hashtagController,
              decoration: InputDecoration(
                hintText: 'lavoro contratto 2024 (# aggiunto auto)',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const Spacer(),

            // Bottone salva
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _selectedFilePath == null || _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Salva file',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
