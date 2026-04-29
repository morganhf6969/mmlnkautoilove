import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:memolink/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/models/saved_item.dart';
import '../../data/repositories/saved_item_repository.dart';
import '../add/add_item_page.dart';
import '../../core/constants/categories.dart';

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
    if (!mounted) return;
    setState(() {
      _allItems = items;
      _applyFilters();
      _loading = false;
    });
  }

  void _applyFilters() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _items = _allItems.where((item) {
        bool matchesHashtag =
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

      _items.sort((a, b) => _sortNewestFirst
          ? b.createdAt.compareTo(a.createdAt)
          : a.createdAt.compareTo(b.createdAt));
    });
  }

  Map<String, dynamic> _getPlatformStyle(String url) {
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
          IconButton(
            icon: Icon(_sortNewestFirst ? Icons.sort : Icons.history),
            onPressed: () {
              setState(() {
                _sortNewestFirst = !_sortNewestFirst;
                _applyFilters();
              });
            },
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
                          padding: const EdgeInsets.all(12),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.85,
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
    final hasTitle = item.ogTitle != null && item.ogTitle!.isNotEmpty;
    final style = _getPlatformStyle(item.url);
    final iconColor = style['color'] as Color;
    final iconData = style['icon'] as IconData; // FontAwesomeIcons è IconData

    return GestureDetector(
      onTap: () => _launchURL(item.url),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Icona social al posto dell'anteprima
            SizedBox(
              height: 80,
              child: Container(
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.08),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(iconData, size: 36, color: iconColor),
                    const SizedBox(height: 6),
                    Text(
                      style['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: iconColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Titolo e hashtag (mai l'URL grezzo)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasTitle)
                      Text(
                        item.ogTitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    if (item.hashtags.isNotEmpty) ...[
                      if (hasTitle) const SizedBox(height: 4),
                      Text(
                        item.hashtags.map((t) => '#$t').join(' '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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
    final categoryNames = appCategories.map((c) => c.label).toList();
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
                value: categoryNames.contains(selectedCategory)
                    ? selectedCategory
                    : categoryNames.first,
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