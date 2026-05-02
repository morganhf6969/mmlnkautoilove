import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:memolink/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import '../../data/models/saved_item.dart';
import '../../data/repositories/saved_item_repository.dart';
import '../../data/database/category_dao.dart';
import '../add/add_item_page.dart';
import '../files/add_file_page.dart';
import '../../core/constants/categories.dart';
import '../../core/constants/iloveabitini_thumbnails.dart';
import '../../core/services/file_service.dart';

class CategoryListPage extends StatefulWidget {
  final String category;

  const CategoryListPage({
    super.key,
    required this.category,
  });

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final SavedItemRepository _repo = SavedItemRepository();

  List<SavedItem> _allItems = [];
  List<SavedItem> _items = [];
  bool _loading = true;
  bool _sortNewestFirst = true;
  String? _selectedHashtag;

  // Lista nomi categorie visibili (caricate dal DB, senza quelle nascoste)
  List<String> _visibleCategoryNames = [];

  // Tiene traccia degli ID già in fetch per non rilanciare richieste duplicate
  final Set<int> _fetchingThumbnails = {};

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _repo.getByCategory(widget.category);

    // Carica TUTTE le categorie dal DB (incluse le nascoste):
    // nel dialog di modifica link ha senso poter spostare un link
    // anche in una categoria nascosta dalla home screen.
    final cats = await CategoryDao().getAll();
    final allNames = cats.map((c) => c.name).toList();

    if (!mounted) return;

    setState(() {
      _allItems = items;
      _visibleCategoryNames = allNames;
      _loading = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    if (!mounted) return;
    final query = _searchController.text.toLowerCase();

    final filtered = _allItems.where((item) {
      final matchesHashtag =
          _selectedHashtag == null || item.hashtags.contains(_selectedHashtag);
      bool matchesQuery = true;
      if (query.isNotEmpty) {
        final titleMatch = (item.ogTitle ?? '').toLowerCase().contains(query);
        final hashtagsMatch =
            item.hashtags.any((tag) => tag.toLowerCase().contains(query));
        matchesQuery = titleMatch || hashtagsMatch;
      }
      return matchesHashtag && matchesQuery;
    }).toList();

    filtered.sort((a, b) => _sortNewestFirst
        ? b.createdAt.compareTo(a.createdAt)
        : a.createdAt.compareTo(b.createdAt));

    setState(() {
      _items = filtered;
    });
  }

  Map<String, dynamic> _getPlatformStyle(String url, {bool isFile = false}) {
    if (isFile) {
      final ext = url.toLowerCase().split('.').last;
      switch (ext) {
        case 'pdf':
          return {'label': 'PDF', 'color': const Color(0xFFE53935), 'icon': FontAwesomeIcons.filePdf};
        case 'doc':
        case 'docx':
          return {'label': 'Word', 'color': const Color(0xFF1565C0), 'icon': FontAwesomeIcons.fileWord};
        case 'xls':
        case 'xlsx':
          return {'label': 'Excel', 'color': const Color(0xFF2E7D32), 'icon': FontAwesomeIcons.fileExcel};
        case 'ppt':
        case 'pptx':
          return {'label': 'PPT', 'color': const Color(0xFFE65100), 'icon': FontAwesomeIcons.filePowerpoint};
        case 'jpg':
        case 'jpeg':
        case 'png':
        case 'heic':
        case 'gif':
        case 'webp':
          return {'label': 'Immagine', 'color': const Color(0xFF6A1B9A), 'icon': FontAwesomeIcons.fileImage};
        case 'mp4':
        case 'mov':
        case 'avi':
          return {'label': 'Video', 'color': const Color(0xFF00695C), 'icon': FontAwesomeIcons.fileVideo};
        case 'mp3':
        case 'm4a':
        case 'wav':
          return {'label': 'Audio', 'color': const Color(0xFF00838F), 'icon': FontAwesomeIcons.fileAudio};
        default:
          return {'label': 'File', 'color': Colors.blueGrey.shade600, 'icon': FontAwesomeIcons.file};
      }
    }
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.contains('instagram.com') || lowerUrl.contains('instagr.am')) {
      return {'label': 'Instagram', 'color': const Color(0xFFE1306C), 'icon': FontAwesomeIcons.instagram};
    } else if (lowerUrl.contains('facebook.com') || lowerUrl.contains('fb.com') || lowerUrl.contains('fb.watch')) {
      return {'label': 'Facebook', 'color': const Color(0xFF1877F2), 'icon': FontAwesomeIcons.facebookF};
    } else if (lowerUrl.contains('tiktok.com') || lowerUrl.contains('vm.tiktok')) {
      return {'label': 'TikTok', 'color': Colors.black, 'icon': FontAwesomeIcons.tiktok};
    } else if (lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be')) {
      return {'label': 'YouTube', 'color': const Color(0xFFFF0000), 'icon': FontAwesomeIcons.youtube};
    } else if (lowerUrl.contains('x.com') || lowerUrl.contains('twitter.com')) {
      return {'label': 'X / Twitter', 'color': Colors.black, 'icon': FontAwesomeIcons.xTwitter};
    } else if (lowerUrl.contains('pinterest.com') || lowerUrl.contains('pin.it')) {
      return {'label': 'Pinterest', 'color': const Color(0xFFE60023), 'icon': FontAwesomeIcons.pinterest};
    } else if (lowerUrl.contains('linkedin.com')) {
      return {'label': 'LinkedIn', 'color': const Color(0xFF0A66C2), 'icon': FontAwesomeIcons.linkedinIn};
    } else if (lowerUrl.contains('spotify.com') || lowerUrl.contains('open.spotify')) {
      return {'label': 'Spotify', 'color': const Color(0xFF1DB954), 'icon': FontAwesomeIcons.spotify};
    } else if (lowerUrl.contains('amazon.') || lowerUrl.contains('amzn.')) {
      return {'label': 'Amazon', 'color': const Color(0xFFFF9900), 'icon': FontAwesomeIcons.amazon};
    } else {
      return {'label': 'WWW', 'color': Colors.blueGrey.shade700, 'icon': FontAwesomeIcons.globe};
    }
  }

  /// Restituisce il widget con il logo/icona social da mostrare nell'angolo della card
  Widget _buildSocialBadge(String url) {
    final lowerUrl = url.toLowerCase();

    Color bgColor;
    Widget iconWidget;

    if (lowerUrl.contains('tiktok.com')) {
      bgColor = Colors.black;
      iconWidget = const Text('TT',
          style: TextStyle(
              color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold));
    } else if (lowerUrl.contains('youtube.com') ||
        lowerUrl.contains('youtu.be')) {
      bgColor = const Color(0xFFFF0000);
      iconWidget =
          const Icon(Icons.play_arrow, color: Colors.white, size: 16);
    } else if (lowerUrl.contains('instagram.com')) {
      bgColor = const Color(0xFFE1306C);
      iconWidget =
          const Icon(Icons.camera_alt, color: Colors.white, size: 14);
    } else if (lowerUrl.contains('facebook.com')) {
      bgColor = const Color(0xFF1877F2);
      iconWidget = const Icon(Icons.facebook, color: Colors.white, size: 16);
    } else if (lowerUrl.contains('x.com') ||
        lowerUrl.contains('twitter.com')) {
      bgColor = Colors.black;
      iconWidget = const Text('X',
          style: TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold));
    } else {
      bgColor = Colors.blueGrey.shade700;
      iconWidget = const Text('W',
          style: TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold));
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2))
        ],
      ),
      child: Center(child: iconWidget),
    );
  }

  /// Recupera il thumbnail in background tramite oEmbed (Instagram/altri) e aggiorna DB + UI
  Future<void> _fetchOgImage(SavedItem item) async {
    if (item.id == null) return;
    if (_fetchingThumbnails.contains(item.id)) return;
    _fetchingThumbnails.add(item.id!);

    try {
      String? imageUrl;

      // Instagram: usa l'API oEmbed pubblica
      if (item.url.contains('instagram.com')) {
        final oembedUrl = Uri.parse(
          'https://api.instagram.com/oembed/?url=${Uri.encodeComponent(item.url)}&maxwidth=640',
        );
        final res = await http.get(oembedUrl).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final json = res.body;
          final match = RegExp('"thumbnail_url"\\s*:\\s*"([^"]+)"').firstMatch(json);
          imageUrl = match?.group(1)?.replaceAll(r'\/', '/');
        }
      }

      // Fallback generico: scraping og:image
      if (imageUrl == null) {
        final res = await http.get(
          Uri.parse(item.url),
          headers: {'User-Agent': 'Mozilla/5.0 (compatible; MemoLink/1.0)'},
        ).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final match = RegExp(
            'property=["\']og:image["\'][^>]+content=["\']([^"\'\\s>]+)',
            caseSensitive: false,
          ).firstMatch(res.body) ??
          RegExp(
            'content=["\']([^"\'\\s>]+)["\'][^>]+property=["\']og:image',
            caseSensitive: false,
          ).firstMatch(res.body);
          imageUrl = match?.group(1);
        }
      }

      if (imageUrl != null && imageUrl.isNotEmpty) {
        final updated = SavedItem(
          id: item.id,
          url: item.url,
          platform: item.platform,
          category: item.category,
          hashtags: item.hashtags,
          createdAt: item.createdAt,
          ogTitle: item.ogTitle,
          ogImage: imageUrl,
        );
        await _repo.save(updated);
        if (mounted) {
          setState(() {
            final idx = _allItems.indexWhere((e) => e.id == item.id);
            if (idx != -1) _allItems[idx] = updated;
            final idx2 = _items.indexWhere((e) => e.id == item.id);
            if (idx2 != -1) _items[idx2] = updated;
          });
        }
      }
    } catch (_) {
      // Silenzioso — ritenterà alla prossima apertura della pagina
    } finally {
      _fetchingThumbnails.remove(item.id);
    }
  }

  Future<void> _openFile(String path) async {
    final result = await OpenFilex.open(path);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossibile aprire il file: ${result.message}')),
      );
    }
  }

  Future<void> _launchURL(String url) async {
    final String trimmedUrl = url.trim();
    if (trimmedUrl.isEmpty) return;
    final Uri uri = Uri.parse(trimmedUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $trimmedUrl: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorOpeningLink)),
        );
      }
    }
  }

  Future<void> _deleteItem(SavedItem item) async {
    if (item.id == null) return;
    if (item.platform == 'file') {
      await FileService.deleteFile(item.url);
    }
    await _repo.delete(item.id!);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: loc.searchByTitleOrTag,
                  border: InputBorder.none,
                ),
                onChanged: (_) => _applyFilters(),
              )
            : Text(localizeDefaultCategory(widget.category, context),
                style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _applyFilters();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'newest') {
                setState(() { _sortNewestFirst = true; });
                _applyFilters();
              } else if (value == 'oldest') {
                setState(() { _sortNewestFirst = false; });
                _applyFilters();
              } else if (value == 'clear') {
                _confirmClearCategory();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'newest',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward_rounded,
                        color: _sortNewestFirst ? Colors.blue : Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text('Dal più recente',
                        style: TextStyle(
                            fontWeight: _sortNewestFirst ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'oldest',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward_rounded,
                        color: !_sortNewestFirst ? Colors.blue : Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text('Dal più vecchio',
                        style: TextStyle(
                            fontWeight: !_sortNewestFirst ? FontWeight.bold : FontWeight.normal)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Svuota categoria', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHashtagBar(),
                Expanded(
                  child: _items.isEmpty
                      ? Center(child: Text(loc.noLinksFound))
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            return _buildGridCard(item);
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_file',
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddFilePage(category: widget.category),
            ),
          );
          if (result == true) _load();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.attach_file_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildHashtagBar() {
    final loc = AppLocalizations.of(context)!;
    final hashtags = <String>{};
    for (var item in _allItems) {
      hashtags.addAll(item.hashtags);
    }
    if (hashtags.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.white,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          ChoiceChip(
            label: Text(loc.all),
            selected: _selectedHashtag == null,
            onSelected: (_) => setState(() {
              _selectedHashtag = null;
              _applyFilters();
            }),
          ),
          ...hashtags.map((tag) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: ChoiceChip(
                  label: Text('#$tag'),
                  selected: _selectedHashtag == tag,
                  onSelected: (_) => setState(() {
                    _selectedHashtag = tag;
                    _applyFilters();
                  }),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildGridCard(SavedItem item) {
    final isFile = item.platform == 'file';
    final hasTitle = item.ogTitle != null && item.ogTitle!.isNotEmpty;
    final style = _getPlatformStyle(item.url, isFile: isFile);
    final iconColor = style['color'] as Color;
    final iconData = style['icon'] as IconData;

    // Risolvi thumbnail: DB → mappa statica → fetch lazy (solo per link, non file)
    final thumbPath = isFile ? null : (item.ogImage?.isNotEmpty == true
        ? item.ogImage
        : kIloveabitiniThumbnails[item.url] ?? kIloveabitiniThumbnails['${item.url}/']);

    if (!isFile && thumbPath == null && item.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fetchOgImage(item));
    }

    return GestureDetector(
      onTap: () => isFile ? _openFile(item.url) : _launchURL(item.url),
      onLongPress: () => _showItemActions(item),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Riga superiore: icona social + data
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: FaIcon(iconData, size: 14, color: iconColor),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${item.createdAt.day.toString().padLeft(2, '0')}/${item.createdAt.month.toString().padLeft(2, '0')}/${item.createdAt.year.toString().substring(2)}',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Corpo: anteprima a sinistra, hashtag a destra
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Anteprima immagine (se disponibile)
                    if (thumbPath != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: SizedBox(
                          width: 72,
                          child: thumbPath.startsWith('assets/')
                              ? Image.asset(
                                  thumbPath,
                                  width: 72,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  thumbPath,
                                  width: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const SizedBox.shrink(),
                                ),
                        ),
                      ),
                    if (thumbPath != null) const SizedBox(width: 8),
                    // Hashtag allineati a destra
                    Expanded(
                      child: Align(
                        alignment: Alignment.topRight,
                        child: item.hashtags.isNotEmpty
                            ? Text(
                                item.hashtags.map((t) => '#$t').join('\n'),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.fade,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue.shade400,
                                  height: 1.5,
                                ),
                              )
                            : hasTitle
                                ? Text(
                                    item.ogTitle!,
                                    textAlign: TextAlign.right,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Placeholder colorato con icona social quando non c'è immagine
  Widget _buildImagePlaceholder(String url) {
    final style = _getPlatformStyle(url);
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: (style['color'] as Color).withOpacity(0.1),
      child: Center(
        child: Icon(
          style['icon'] as IconData,
          size: 40,
          color: (style['color'] as Color).withOpacity(0.5),
        ),
      ),
    );
  }

  void _showItemActions(SavedItem item) {
    final loc = AppLocalizations.of(context)!;
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
              _showEditDialog(item);
            },
          ),
          ListTile(
            leading: const Icon(Icons.share_rounded, color: Colors.green),
            title: const Text('Condividi'),
            onTap: () async {
              final size = MediaQuery.of(context).size;
              Navigator.pop(context);
              // Aspetta che il bottom sheet sia completamente chiuso prima di aprire il share sheet su iOS
              await Future.delayed(const Duration(milliseconds: 400));
              if (!mounted) return;
              await Share.share(
                item.url,
                sharePositionOrigin: Rect.fromCenter(
                  center: Offset(size.width / 2, size.height / 2),
                  width: 200,
                  height: 200,
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_rounded, color: Colors.red),
            title: Text(loc.delete, style: const TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _confirmDelete(item);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showEditDialog(SavedItem item) {
    // Usa la lista già caricata in _load() — include tutte le categorie
    // visibili (dal DB, escluse le nascoste), aggiornata ad ogni apertura pagina.
    final categoryNames = List<String>.from(_visibleCategoryNames);

    // Se la categoria del link non compare nella lista visibile (es. è nascosta),
    // aggiungila comunque per evitare un valore non valido nel dropdown.
    if (!categoryNames.contains(item.category)) {
      categoryNames.insert(0, item.category);
    }

    String selectedCategory = item.category;
    final hashtagController =
        TextEditingController(text: item.hashtags.join(' '));

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Modifica'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Categoria',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                items: categoryNames
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setStateDialog(() => selectedCategory = v);
                },
              ),
              const SizedBox(height: 16),
              const Text('Hashtag (separati da spazio)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: hashtagController,
                decoration: const InputDecoration(
                  hintText: '#viaggio #food',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla')),
            TextButton(
              onPressed: () async {
                final newHashtags = hashtagController.text
                    .split(RegExp(r'[\s,]+'))
                    .map((t) => t.replaceAll('#', '').trim())
                    .where((t) => t.isNotEmpty)
                    .toList();
                final updated = SavedItem(
                  id: item.id,
                  url: item.url,
                  platform: item.platform,
                  category: selectedCategory,
                  hashtags: newHashtags,
                  createdAt: item.createdAt,
                  ogTitle: item.ogTitle,
                  ogImage: item.ogImage,
                );
                await _repo.save(updated);
                if (ctx.mounted) Navigator.pop(ctx);
                _load();
              },
              child: const Text('Salva',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearCategory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Svuota categoria'),
        content: Text(
            'Vuoi eliminare tutti i ${_allItems.length} link in "${widget.category}"? L\'operazione non è reversibile.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _repo.deleteByCategory(widget.category);
              _load();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Categoria svuotata ✓')),
                );
              }
            },
            child: const Text('Elimina tutto',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(SavedItem item) {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.delete),
        content: Text(loc.deleteMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc.cancel)),
          TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteItem(item);
              },
              child: Text(loc.confirmDeleteButton,
                  style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}