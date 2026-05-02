import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/file_service.dart';
import '../../data/models/saved_item.dart';
import '../../data/repositories/saved_item_repository.dart';
import '../../data/database/category_dao.dart';

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
  String _selectedCategory = '';
  List<String> _categoryNames = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
    _loadCategories();
    _hashtagController.addListener(_formatHashtags);
  }

  void _formatHashtags() {
    if (_formattingHashtags) return;
    final text = _hashtagController.text;
    if (text.isEmpty) return;

    // Formatta solo se l'utente ha appena digitato uno spazio
    if (!text.endsWith(' ')) return;

    _formattingHashtags = true;
    final words = text.trim().split(RegExp(r'\s+'));
    final formatted = words
        .where((w) => w.isNotEmpty)
        .map((w) => w.startsWith('#') ? w : '#$w')
        .join(' ');
    _hashtagController.value = TextEditingValue(
      text: '$formatted ',
      selection: TextSelection.collapsed(offset: formatted.length + 1),
    );
    _formattingHashtags = false;
  }

  Future<void> _loadCategories() async {
    final cats = await CategoryDao().getAll();
    setState(() {
      _categoryNames = cats.map((c) => c.name).toList();
    });
  }

  Future<void> _createNewCategory() async {
    final nameController = TextEditingController();
    String selectedEmoji = '📁';

    final List<String> emojis = [
      '📁','📂','🗂️','📋','📌','📎','🗒️','📝','💼','🏠',
      '❤️','⭐','🎯','🎨','🎵','📸','🎬','💡','🔑','🌟',
      '💄','🧠','💰','☕','🌱','💕','🔮','🤖','💃','👶',
      '🧴','🥑','🎙️','🛋️','🐱','🍹','🌿','🏃','🪴','💼',
    ];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Nuova cartella'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Nome cartella',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Icona', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 8, mainAxisSpacing: 4, crossAxisSpacing: 4),
                  itemCount: emojis.length,
                  itemBuilder: (_, i) => GestureDetector(
                    onTap: () => setStateDialog(() => selectedEmoji = emojis[i]),
                    child: Container(
                      decoration: BoxDecoration(
                        color: selectedEmoji == emojis[i]
                            ? Colors.blue.shade100
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(child: Text(emojis[i], style: const TextStyle(fontSize: 20))),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                // iconCode >= 100 = emoji, indice nell'array
                final emojiIdx = emojis.indexOf(selectedEmoji);
                final iconCode = emojiIdx >= 0 ? 100 + emojiIdx : 100;
                await CategoryDao().insert(name, iconCode);
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadCategories();
                setState(() => _selectedCategory = name);
              },
              child: const Text('Crea', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
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
        category: _selectedCategory,
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

            // Categoria
            const Text('Categoria',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _categoryNames.contains(_selectedCategory)
                            ? _selectedCategory
                            : null,
                        isExpanded: true,
                        hint: Text(_selectedCategory),
                        items: _categoryNames
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedCategory = v);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _createNewCategory,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ],
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
