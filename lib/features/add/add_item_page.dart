import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:memolink/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import '../../data/models/saved_item.dart';
import '../../data/repositories/saved_item_repository.dart';
import '../../data/database/category_dao.dart';
import '../../core/constants/categories.dart';

class AddItemPage extends StatefulWidget {
  final SavedItem? existingItem;
  final String? initialUrl;

  const AddItemPage({
    super.key,
    this.existingItem,
    this.initialUrl,
  });

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final SavedItemRepository _repo = SavedItemRepository();
  final CategoryDao _categoryDao = CategoryDao();

  final TextEditingController _urlCtrl = TextEditingController();
  final TextEditingController _hashtagsCtrl = TextEditingController();

  List<Category> _categories = [];
  Category? _selectedCategory;
  bool _saving = false;

  bool _fetchingPreview = false;
  String? _previewTitle;
  String? _previewImage;
  Timer? _debounce;

  // Credenziali Meta per oEmbed
  static const String _metaAppId = '1058592187334261';
  static const String _metaAppSecret = '3f98c70189ac8e9237a879ae712638ec';

  final List<String> _defaultImages = const [
    'arte.png', 'cucina.png', 'divertente.png', 'luoghi.png',
    'moda.png', 'musica.png', 'shopping.png', 'social.png', 'tecnologia.png',
    'iloveabitini.png',
  ];

  final List<String> _emojiOptions = const [
    '🌶️', '😂', '✈️', '🏠', '🍕', '⚽', '🎮', '🐾',
    '🎬', '💡', '🎁', '🛒', '📸', '🧘', '🚀', '🔥',
    '🌸', '💻', '🎵', '📚', '⚡', '🎨', '🏋️', '🌙',
    '☀️', '🎭', '🍰', '🏖️', '🎪', '💎', '💬', '🎓',
    '🏆', '🎯', '🌍', '🚗', '📱', '👔', '🎸', '🍎',
    '🥗', '🍣', '🎂', '⚙️', '🔐', '📊', '🌺', '🦋',
    '🎈', '👗', '🏥', '✨',
    // Social media topics
    '💄', '🧠', '💰', '☕', '🌱', '💕', '🔮', '🤖',
    '💃', '👶', '🧴', '🥑', '🎙️', '💼', '🛋️', '🐱',
    '🍹', '🌿', '🏃', '🪴',
  ];

  bool get _isEdit => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _hashtagsCtrl.addListener(_onHashtagsChanged);
    _urlCtrl.addListener(_onUrlChanged);

    if (_isEdit) {
      final item = widget.existingItem!;
      _urlCtrl.text = item.url;
      _hashtagsCtrl.text =
          item.hashtags.map((t) => t.startsWith('#') ? t : '#$t').join(', ');
      _previewTitle = item.ogTitle;
      _previewImage = item.ogImage;
    } else {
      // Primo controlla se c'è un URL condiviso da un'altra app
      _loadSharedUrl();

      // Oppure usa l'URL iniziale passato come parametro
      if (widget.initialUrl != null && widget.initialUrl!.isNotEmpty) {
        _urlCtrl.text = widget.initialUrl!;
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _fetchPreview(widget.initialUrl!));
      }
    }
  }

  Future<void> _loadSharedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final sharedUrl = prefs.getString('shared_url');

    if (sharedUrl != null && sharedUrl.isNotEmpty && mounted) {
      _urlCtrl.text = sharedUrl;
      // Rimuovi il link condiviso dopo averlo caricato
      await prefs.remove('shared_url');
      // Fetcha l'anteprima del link
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _fetchPreview(sharedUrl));
    }
  }

  void _onUrlChanged() {
    _debounce?.cancel();
    final url = _urlCtrl.text.trim();
    if (url.length < 10) {
      setState(() {
        _previewTitle = null;
        _previewImage = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _fetchPreview(url);
    });
  }

  bool _isInstagram(String url) => url.contains('instagram.com');
  bool _isFacebook(String url) =>
      url.contains('facebook.com') || url.contains('fb.watch');
  bool _isTikTok(String url) =>
      url.contains('tiktok.com') || url.contains('vm.tiktok.com');

  Future<void> _fetchPreview(String url) async {
    if (!url.startsWith('http')) return;
    setState(() => _fetchingPreview = true);

    try {
      if (_isInstagram(url)) {
        await _fetchInstagramPreview(url);
      } else if (_isFacebook(url)) {
        await _fetchFacebookPreview(url);
      } else if (_isTikTok(url)) {
        await _fetchTikTokPreview(url);
      } else {
        await _fetchGenericPreview(url);
      }
    } catch (_) {
      if (mounted) setState(() => _fetchingPreview = false);
    }
  }

  Future<void> _fetchInstagramPreview(String url) async {
    final accessToken = '$_metaAppId|$_metaAppSecret';
    final apiUrl = Uri.parse(
      'https://graph.facebook.com/v17.0/instagram_oembed'
      '?url=${Uri.encodeComponent(url)}'
      '&access_token=$accessToken'
      '&fields=title,thumbnail_url',
    );

    try {
      final response = await http.get(apiUrl).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final title = data['title'] ?? data['author_name'];
        if (mounted) {
          setState(() {
            _previewTitle = title;
            _previewImage = data['thumbnail_url'];
            _fetchingPreview = false;
          });
        }
      } else {
        if (mounted) setState(() => _fetchingPreview = false);
      }
    } catch (_) {
      if (mounted) setState(() => _fetchingPreview = false);
    }
  }

  Future<void> _fetchFacebookPreview(String url) async {
    final accessToken = '$_metaAppId|$_metaAppSecret';
    final apiUrl = Uri.parse(
      'https://graph.facebook.com/v17.0/oembed_post'
      '?url=${Uri.encodeComponent(url)}'
      '&access_token=$accessToken'
      '&fields=title,thumbnail_url',
    );

    try {
      final response = await http.get(apiUrl).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final title = data['title'] ?? data['author_name'];
        if (mounted) {
          setState(() {
            _previewTitle = title;
            _previewImage = data['thumbnail_url'];
            _fetchingPreview = false;
          });
        }
      } else {
        if (mounted) setState(() => _fetchingPreview = false);
      }
    } catch (_) {
      if (mounted) setState(() => _fetchingPreview = false);
    }
  }

  Future<void> _fetchTikTokPreview(String url) async {
    final apiUrl = Uri.parse(
      'https://www.tiktok.com/oembed?url=${Uri.encodeComponent(url)}',
    );
    try {
      final response = await http.get(apiUrl).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final title = data['title'] ?? data['author_name'];
        if (mounted) {
          setState(() {
            _previewTitle = title;
            _previewImage = data['thumbnail_url'];
            _fetchingPreview = false;
          });
        }
      } else {
        if (mounted) setState(() => _fetchingPreview = false);
      }
    } catch (_) {
      if (mounted) setState(() => _fetchingPreview = false);
    }
  }

  Future<void> _fetchGenericPreview(String url) async {
    final response = await http.get(
      Uri.parse(url),
      headers: {'User-Agent': 'Mozilla/5.0 (compatible; Memolink/1.0)'},
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode == 200) {
      final body = response.body;
      final title = _extractMeta(body, 'og:title') ??
          _extractMeta(body, 'twitter:title') ??
          _extractTitle(body);
      final image = _extractMeta(body, 'og:image') ??
          _extractMeta(body, 'twitter:image');
      if (mounted) {
        setState(() {
          _previewTitle = _decodeHtmlEntities(title);
          _previewImage = image;
          _fetchingPreview = false;
        });
      }
    } else {
      if (mounted) setState(() => _fetchingPreview = false);
    }
  }

  String? _decodeHtmlEntities(String? text) {
    if (text == null) return null;
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&#064;', '@')
        .replaceAll('&nbsp;', ' ');
  }

  String? _extractMeta(String html, String property) {
    final patterns = [
      RegExp('property=["\']$property["\'][^>]*content=["\'](.*?)["\']',
          caseSensitive: false),
      RegExp('content=["\'](.*?)["\'][^>]*property=["\']$property["\']',
          caseSensitive: false),
      RegExp('name=["\']$property["\'][^>]*content=["\'](.*?)["\']',
          caseSensitive: false),
    ];
    for (final r in patterns) {
      final m = r.firstMatch(html);
      if (m != null && m.group(1)!.isNotEmpty) return m.group(1);
    }
    return null;
  }

  String? _extractTitle(String html) {
    final r = RegExp(r'<title[^>]*>(.*?)<\/title>', caseSensitive: false);
    final m = r.firstMatch(html);
    return m?.group(1)?.trim();
  }


  void _onHashtagsChanged() {
    String text = _hashtagsCtrl.text;
    if (text.isNotEmpty && !text.startsWith('#')) {
      text = '#$text';
      _updateHashtagController(text);
      return;
    }
    if (text.endsWith(' ')) {
      String trimmed = text.trim();
      if (trimmed.isNotEmpty && !trimmed.endsWith(',')) {
        text = '$trimmed, #';
        _updateHashtagController(text);
      }
    }
  }

  void _updateHashtagController(String text) {
    _hashtagsCtrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _categoryDao.getAll();
      final prefs = await SharedPreferences.getInstance();
      final hidden = prefs.getStringList('hidden_categories') ?? [];
      final visible = cats.where((c) => !hidden.contains(c.name)).toList();
      if (!mounted) return;
      setState(() {
        _categories = visible;
        _selectedCategory = visible.isNotEmpty
            ? visible.firstWhere(
                (c) => c.name == widget.existingItem?.category,
                orElse: () => visible.first,
              )
            : null;
      });
    } catch (e) {
      debugPrint("Errore: $e");
    }
  }

  List<String> _parseHashtags(String raw) {
    return raw
        .split(',')
        .map((e) => e.replaceAll('#', '').trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (_selectedCategory == null) return;
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) return;

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool isPremium = prefs.getBool('is_premium') ?? false;

      final item = SavedItem(
        id: widget.existingItem?.id,
        url: url,
        platform: _detectPlatform(url),
        category: _selectedCategory!.name,
        hashtags: _parseHashtags(_hashtagsCtrl.text),
        createdAt: widget.existingItem?.createdAt ?? DateTime.now(),
        ogTitle: _previewTitle,
        ogImage: _previewImage,
      );

      await _repo.save(item, isPremium: isPremium);

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains("Limite")) {
          _showPremiumDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Errore durante il salvataggio: $e")),
          );
        }
      }
    }
  }

  void _showPremiumDialog() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.limitReached),
        content: Text(loc.limitReachedMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await RevenueCatUI.presentPaywallIfNeeded('Memolink Premium');
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${loc.errorOperation}: $e'), behavior: SnackBarBehavior.floating),
                  );
                }
              }
            },
            child: Text(loc.becomePremium),
          ),
        ],
      ),
    );
  }

  String _detectPlatform(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('facebook.com') || lower.contains('fb.watch'))
      return 'facebook';
    if (lower.contains('instagram')) return 'instagram';
    if (lower.contains('tiktok')) return 'tiktok';
    if (lower.contains('youtube') || lower.contains('youtu.be'))
      return 'youtube';
    if (lower.contains('x.com') || lower.contains('twitter')) return 'x';
    return 'manual';
  }

  Widget _buildAddCategoryButton() {
    final loc = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () => _showCategoryDialog(categoryToEdit: null),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, size: 32, color: Colors.black),
            const SizedBox(height: 8),
            Text(loc.newCategoryButtonLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(Category category) {
    final isSelected = _selectedCategory?.id == category.id;

    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
      },
      onLongPress: () {
        _showCategoryDialog(categoryToEdit: category);
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.shade50 : Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCategoryIconWidget(category.iconCode),
            const SizedBox(height: 8),
            Text(
              localizeDefaultCategory(category.name, context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Restituisce l'emoji corrispondente all'iconCode.
  /// iconCode >= 100 → emoji (index = iconCode - 100)
  /// iconCode < 100  → immagine asset (gestita da _resolveImagePath)
  String _resolveEmoji(int? iconCode) {
    if (iconCode != null && iconCode >= 100) {
      final idx = iconCode - 100;
      if (idx < _emojiOptions.length) return _emojiOptions[idx];
    }
    return ''; // immagine gestita separatamente
  }

  /// Restituisce il path dell'immagine per iconCode 0-9, null altrimenti.
  String? _resolveImagePath(int? iconCode) {
    if (iconCode != null && iconCode >= 0 && iconCode < _defaultImages.length) {
      return 'assets/images/categories/${_defaultImages[iconCode]}';
    }
    return null;
  }

  /// Widget icona categoria: immagine se iconCode < 100, emoji altrimenti.
  Widget _buildCategoryIconWidget(int? iconCode) {
    final imagePath = _resolveImagePath(iconCode);
    if (imagePath != null) {
      return Image.asset(imagePath, width: 32, height: 32, fit: BoxFit.contain);
    }
    final emoji = _resolveEmoji(iconCode);
    if (emoji.isNotEmpty) {
      return Text(emoji, style: const TextStyle(fontSize: 32));
    }
    return const Text('📁', style: TextStyle(fontSize: 32));
  }

  void _showCategoryDialog({Category? categoryToEdit}) {
    final loc = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: categoryToEdit?.name);
    int selectedIconCode = categoryToEdit?.iconCode ?? 100;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          scrollable: true,
          title: Text(categoryToEdit == null ? loc.newCategoryDialog : loc.editCategoryDialog),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(hintText: loc.categoryNameHint),
              ),
              const SizedBox(height: 15),
              Text(loc.selectIconLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              const SizedBox(height: 10),
              SizedBox(
                height: 250,
                width: double.maxFinite,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                  itemCount: _emojiOptions.length,
                  itemBuilder: (context, index) {
                    final currentCode = index + 100;
                    return GestureDetector(
                      onTap: () => setStateDialog(() => selectedIconCode = currentCode),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedIconCode == currentCode ? Colors.blue : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(_emojiOptions[index], style: const TextStyle(fontSize: 28)),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancel),
            ),
            if (categoryToEdit != null)
              TextButton(
                onPressed: () async {
                  final index = _categories.indexWhere((c) => c.id == categoryToEdit.id);
                  if (index >= 0) {
                    _categories.removeAt(index);
                  }
                  Navigator.pop(context);
                  setState(() {});
                },
                child: Text(loc.delete, style: const TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty) {
                  Navigator.pop(context);
                  return;
                }
                if (categoryToEdit == null) {
                  final newCategory = Category(
                    id: DateTime.now().millisecondsSinceEpoch,
                    name: nameCtrl.text,
                    iconCode: selectedIconCode,
                    position: _categories.length,
                  );
                  await _categoryDao.insert(nameCtrl.text, selectedIconCode);
                  _categories.add(newCategory);
                } else {
                  final index = _categories.indexWhere((c) => c.id == categoryToEdit.id);
                  if (index >= 0) {
                    _categories[index] = Category(
                      id: categoryToEdit.id,
                      name: nameCtrl.text,
                      iconCode: selectedIconCode,
                      position: categoryToEdit.position,
                    );
                  }
                }
                Navigator.pop(context);
                setState(() {});
              },
              child: Text(loc.save),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _hashtagsCtrl.removeListener(_onHashtagsChanged);
    _urlCtrl.removeListener(_onUrlChanged);
    _urlCtrl.dispose();
    _hashtagsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEdit ? loc.editLinkTitle : loc.addLinkTitle),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _urlCtrl,
                decoration: InputDecoration(
                  labelText: loc.link,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.link),
                  suffixIcon: _fetchingPreview
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
              ),

              if (_previewImage != null || _previewTitle != null) ...[
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      if (_previewImage != null)
                        ClipRRect(
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(12)),
                          child: Image.network(
                            _previewImage!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox(width: 80, height: 80),
                          ),
                        ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Text(
                            _previewTitle ?? '',
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              Text(loc.selectCategoryLabel,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildAddCategoryButton();
                    }
                    return _buildCategoryCard(_categories[index - 1]);
                  },
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _hashtagsCtrl,
                decoration: InputDecoration(
                  labelText: loc.hashtag,
                  hintText: loc.hashtaginput,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(loc.saveLink,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
