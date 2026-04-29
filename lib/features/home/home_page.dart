import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:memolink/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../data/repositories/saved_item_repository.dart';
import '../../data/database/category_dao.dart';
import '../../data/models/saved_item.dart';
import '../add/add_item_page.dart';
import '../list/category_list_page.dart';
import 'widgets/category_grid.dart';
import 'widgets/category_item.dart';
import '../settings/settings_page.dart';
import '../../core/constants/categories.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  static const _platform = MethodChannel('com.memolink.sharing/channel');
  final SavedItemRepository _repo = SavedItemRepository();
  final CategoryDao _categoryDao = CategoryDao();
  
  List<Category> _categories = [];
  List<Category> _filteredCategories = [];
  List<SavedItem> _searchResultsItems = [];
  Map<String, int> _counters = {};
  List<String> _hiddenCategories = [];

  bool _editMode = false;
  bool _isSearching = false;
  bool _isPremium = false; 
  int _currentColumns = 4;
  final TextEditingController _searchCtrl = TextEditingController();

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
    '🎈', '👗', '🏥', '✨'
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadAll(); // Carica subito dalla cache locale
    _refreshPremiumStatus(); // Verifica premium in background (rete)
    // Controlla subito se c'è un link da condivisione in attesa
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSharedUrl());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadAll(); // Aggiorna categorie e contatori immediatamente dalla cache locale
      _checkSharedUrl();
      _syncAndReloadPremium(); // Forza sincronizzazione con Apple dopo riscatto codice promo
    }
  }

  Future<void> _syncAndReloadPremium() async {
    try {
      // restorePurchases chiede ad Apple lo stato attuale, necessario per i codici promo
      await Purchases.restorePurchases();
    } catch (e) {
      debugPrint("Errore restore acquisti: $e");
    }
    await _refreshPremiumStatus();
  }

  Future<void> _checkSharedUrl() async {
    if (!mounted) return;
    try {
      final sharedUrl = await _platform.invokeMethod<String>('getSharedUrl');
      if (sharedUrl != null && sharedUrl.isNotEmpty && mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => AddItemPage(initialUrl: sharedUrl)),
        );
        _loadAll();
      }
    } catch (_) {}
  }

  /// Ricarica categorie, contatori e preferenze dal DB locale (veloce, nessuna rete).
  Future<void> _loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final premiumStatus = prefs.getBool('is_premium') ?? false;

    final cats = await _categoryDao.getAll();
    final Map<String, int> counters = {};
    for (final cat in cats) {
      counters[cat.name] = await _repo.countByCategory(cat.name);
    }
    final hidden = prefs.getStringList('hidden_categories') ?? [];

    if (mounted) {
      setState(() {
        _categories = cats;
        _hiddenCategories = hidden;
        _filteredCategories = cats.where((c) => !hidden.contains(c.name)).toList();
        _counters = counters;
        _currentColumns = prefs.getInt('grid_columns') ?? 4;
        _isPremium = premiumStatus;
      });
    }
  }

  /// Verifica lo stato premium tramite RevenueCat (con chiamata di rete).
  /// Aggiorna SharedPreferences e poi ricarica la UI.
  Future<void> _refreshPremiumStatus() async {
    final prefs = await SharedPreferences.getInstance();
    bool premiumStatus = prefs.getBool('is_premium') ?? false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      premiumStatus = customerInfo.entitlements.all['Memolink Premium']?.isActive ?? false;
      await prefs.setBool('is_premium', premiumStatus);
    } catch (e) {
      debugPrint("Errore recupero info RevenueCat: $e");
    }
    if (mounted) {
      setState(() => _isPremium = premiumStatus);
    }
  }

  void _onSearchChanged(String query) async {
    if (query.isEmpty) {
      setState(() {
        _filteredCategories = _categories;
        _searchResultsItems = [];
      });
      return;
    }
    final lowerQuery = query.toLowerCase();
    final matchedCategories = _categories
        .where((c) => c.name.toLowerCase().contains(lowerQuery))
        .toList();
    final allItems = await _repo.getAll();
    final matchedItems = allItems.where((item) {
      final titleMatch = (item.ogTitle ?? '').toLowerCase().contains(lowerQuery);
      final hashtagsMatch = item.hashtags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      return titleMatch || hashtagsMatch;
    }).toList();

    setState(() {
      _filteredCategories = matchedCategories;
      _searchResultsItems = matchedItems;
    });
  }

  Map<String, dynamic> _getPlatformStyle(String url) {
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('instagram.com')) return {'label': 'Instagram', 'color': const Color(0xFFE1306C), 'icon': Icons.camera_alt};
    if (lowerUrl.contains('facebook.com')) return {'label': 'Facebook', 'color': const Color(0xFF1877F2), 'icon': Icons.facebook};
    if (lowerUrl.contains('tiktok.com')) return {'label': 'TikTok', 'color': Colors.black, 'icon': Icons.music_note};
    if (lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be')) return {'label': 'YouTube', 'color': const Color(0xFFFF0000), 'icon': Icons.play_arrow};
    if (lowerUrl.contains('x.com') || lowerUrl.contains('twitter.com')) return {'label': 'X', 'color': Colors.black, 'icon': Icons.close};
    return {'label': 'Apri Link', 'color': Colors.blueGrey.shade700, 'icon': Icons.language};
  }

  Future<void> _launchURL(String url) async {
    final String trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return;
    
    final Uri uri = Uri.parse(trimmedUrl);
    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      debugPrint('Could not launch $trimmedUrl: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorOpeningLink)),
        );
      }
    }
  }

  Widget _buildSearchResults() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResultsItems.length,
      itemBuilder: (context, index) {
        final item = _searchResultsItems[index];
        final style = _getPlatformStyle(item.url);
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: ListTile(
            leading: Icon(style['icon'], color: style['color']),
            title: Text(item.ogTitle ?? 'Link'),
            subtitle: Text(item.category),
            onTap: () => _launchURL(item.url),
          ),
        );
      },
    );
  }

  void _showCategoryDialog({Category? categoryToEdit}) {
    final loc = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController(text: categoryToEdit?.name);
    int selectedIconCode = categoryToEdit?.iconCode ?? 100;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(categoryToEdit == null ? loc.newCategoryTitle : loc.editCategoryTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(hintText: loc.categoryNameHint)),
              const SizedBox(height: 15),
              SizedBox(
                height: 250,
                width: double.maxFinite,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                  itemCount: _emojiOptions.length,
                  itemBuilder: (context, index) {
                    int currentCode = index + 100;
                    return GestureDetector(
                      onTap: () => setStateDialog(() => selectedIconCode = currentCode),
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: selectedIconCode == currentCode ? Colors.blue : Colors.transparent, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(_emojiOptions[index], style: const TextStyle(fontSize: 32)),
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.cancel)),
            TextButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty) {
                  if (categoryToEdit == null) {
                    await _categoryDao.insert(nameCtrl.text, selectedIconCode);
                  } else {
                    await _categoryDao.updateNameAndIcon(categoryToEdit.id!, nameCtrl.text, selectedIconCode);
                  }
                  Navigator.pop(context);
                  _loadAll();
                }
              },
              child: Text(loc.save),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAction({required IconData icon, required String label, VoidCallback? onTap, bool isActive = false}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? Colors.blue : Colors.black87, size: 20),
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showCategoryActions(String categoryName) {
    final isDeletable = !nonDeletableCategories.contains(categoryName);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: Colors.blue),
            title: const Text('Modifica'),
            onTap: () {
              Navigator.pop(context);
              final cat = _categories.firstWhere((c) => c.name == categoryName);
              _showCategoryDialog(categoryToEdit: cat);
            },
          ),
          ListTile(
            leading: const Icon(Icons.ios_share_rounded, color: Colors.green),
            title: const Text('Condividi categoria'),
            onTap: () {
              Navigator.pop(context);
              _shareCategory(categoryName);
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off_rounded, color: Colors.grey),
            title: const Text('Nascondi'),
            onTap: () {
              Navigator.pop(context);
              _hideCategory(categoryName);
            },
          ),
          if (isDeletable)
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text('Cancella', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                final cat = _categories.firstWhere((c) => c.name == categoryName);
                _confirmDeleteCategory(cat.id!);
              },
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _hashPin(String pin) {
    return sha256.convert(utf8.encode(pin)).toString();
  }

  Future<void> _hideCategory(String categoryName) async {
    final prefs = await SharedPreferences.getInstance();
    final existingHash = prefs.getString('hidden_pin');

    if (existingHash == null) {
      // Prima volta — imposta il PIN
      await _showSetPinDialog(onConfirmed: (pin) async {
        await prefs.setString('hidden_pin', _hashPin(pin));
        final hidden = prefs.getStringList('hidden_categories') ?? [];
        hidden.add(categoryName);
        await prefs.setStringList('hidden_categories', hidden);
        _loadAll();
      });
    } else {
      // PIN già impostato — nascondi direttamente
      final hidden = prefs.getStringList('hidden_categories') ?? [];
      if (!hidden.contains(categoryName)) hidden.add(categoryName);
      await prefs.setStringList('hidden_categories', hidden);
      _loadAll();
    }
  }

  Future<void> _showSetPinDialog({required Future<void> Function(String) onConfirmed}) async {
    final pinCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Imposta codice'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Crea un codice per accedere alle categorie nascoste.'),
              const SizedBox(height: 12),
              TextField(
                controller: pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Codice', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Conferma codice', border: OutlineInputBorder()),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
            TextButton(
              onPressed: () async {
                if (pinCtrl.text.length < 4) {
                  setStateDialog(() => error = 'Minimo 4 cifre');
                  return;
                }
                if (pinCtrl.text != confirmCtrl.text) {
                  setStateDialog(() => error = 'I codici non corrispondono');
                  return;
                }
                Navigator.pop(ctx);
                await onConfirmed(pinCtrl.text);
              },
              child: const Text('Salva', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareCategory(String categoryName) async {
    final screenSize = MediaQuery.of(context).size; // cattura prima di qualsiasi await
    final items = await _repo.getByCategory(categoryName);
    if (!mounted) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessun link da condividere in questa categoria.')),
      );
      return;
    }

    // Mostra loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final payload = jsonEncode({
        'category': categoryName,
        'items': items.map((item) => {
          'url': item.url,
          'platform': item.platform,
          'hashtags': item.hashtags,
          'ogTitle': item.ogTitle,
        }).toList(),
      });

      final response = await http.post(
        Uri.parse('https://api.memolink.info/share'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'payload': payload}),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;
      Navigator.pop(context); // chiudi loading — da qui il dialog è chiuso

      if (response.statusCode == 200) {
        final id = jsonDecode(response.body)['id'] as String;
        final link = 'https://memolink.info/import/$id';
        // Aspetta che il dialog sia completamente chiuso prima di aprire il share sheet
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        // Try-catch separato: se Share lancia, NON tentiamo un secondo Navigator.pop
        try {
          await Share.share(
            'Guarda la mia categoria "$categoryName" su MemoLink!\n\n$link',
            subject: 'Categoria MemoLink: $categoryName',
            sharePositionOrigin: Rect.fromCenter(
              center: Offset(screenSize.width / 2, screenSize.height / 2),
              width: 200,
              height: 200,
            ),
          );
        } catch (shareError) {
          debugPrint('❌ share error: $shareError');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Errore condivisione: $shareError')),
            );
          }
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Errore del server. Riprova più tardi.')),
        );
      }
    } catch (e, stack) {
      // Raggiunto solo se http.post o json parsing fallisce (dialog ancora aperto)
      debugPrint('❌ _shareCategory error: $e');
      debugPrint('$stack');
      if (mounted) {
        Navigator.pop(context); // chiudi dialog solo in questo caso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteCategory(int categoryId) async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.deleteCategoryTitle),
        content: Text(loc.deleteCategoryMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.confirmDeleteButton, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _categoryDao.delete(categoryId);
      _loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: _isSearching ? 140 : 130,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('MemoLink', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 28)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _isPremium ? Colors.amber : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isPremium ? loc.premium : loc.free,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _isPremium ? Colors.black : Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
              child: _isSearching 
                ? TextField(
                    controller: _searchCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: loc.categorySearchHint,
                      border: InputBorder.none,
                      suffixIcon: IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _isSearching = false)),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTopAction(icon: Icons.search, label: loc.search, onTap: () => setState(() => _isSearching = true)),
                      _buildTopAction(icon: Icons.edit, label: loc.edit, isActive: _editMode, onTap: () => setState(() => _editMode = !_editMode)),
                      InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddItemPage())).then((_) => _loadAll()),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircleAvatar(backgroundColor: Colors.black, radius: 15, child: Icon(Icons.add, color: Colors.white, size: 20)),
                            Text(loc.link, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                      _buildTopAction(icon: Icons.add_circle_outline, label: loc.newCategory, onTap: () => _showCategoryDialog()),
                      _buildTopAction(icon: Icons.settings, label: loc.settings, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())).then((_) => _loadAll()),
                      ),
                    ],
                  ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!_isPremium)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())).then((_) => _loadAll()),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade400, Colors.orange.shade700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.orange.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.upgradeToPremium,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              loc.upgradeSubtitle,
                              style: const TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          Expanded(
            child: _isSearching && _searchResultsItems.isNotEmpty
                ? _buildSearchResults()
                : CategoryGrid(
                    categories: _filteredCategories,
                    columns: _currentColumns,
                    editMode: _editMode,
                    nonDeletable: nonDeletableCategories,
                    items: _filteredCategories.map((cat) {
                      String? imagePath;
                      String? emoji;
                      if (cat.iconCode != null) {
                        if (cat.iconCode! >= 100) {
                          int emojiIndex = cat.iconCode! - 100;
                          if (emojiIndex < _emojiOptions.length) emoji = _emojiOptions[emojiIndex];
                        } else if (cat.iconCode! < _defaultImages.length) {
                          imagePath = 'assets/images/categories/${_defaultImages[cat.iconCode!]}';
                        }
                      }
                      return CategoryItem(
                        label: localizeDefaultCategory(cat.name, context),
                        count: _counters[cat.name] ?? 0,
                        imagePath: imagePath,
                        emoji: emoji,
                        gradient: const [Colors.white, Colors.white],
                        icon: Icons.folder,
                      );
                    }).toList(),
                    onDelete: (id) => _confirmDeleteCategory(id),
                    onEdit: (label) => _showCategoryDialog(categoryToEdit: _categories.firstWhere((c) => c.name == label)),
                    onReorder: (list) async { await _categoryDao.updatePositions(list); _loadAll(); },
                    onLongPress: (label) => _showCategoryActions(label),
                    onTap: (label) => Navigator.push(context, MaterialPageRoute(builder: (_) => CategoryListPage(category: label))).then((_) => _loadAll()),
                  ),
          ),
        ],
      ),
    );
  }
}