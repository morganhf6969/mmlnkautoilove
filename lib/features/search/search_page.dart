import 'package:flutter/material.dart';
import 'package:memolink/l10n/app_localizations.dart';

import '../../data/models/saved_item.dart';
import '../../data/repositories/saved_item_repository.dart';
import '../add/add_item_page.dart';
import '../preview/item_preview_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SavedItemRepository _repo = SavedItemRepository();
  final TextEditingController _queryCtrl = TextEditingController();

  List<SavedItem> _results = [];
  bool _loading = false;
  bool _sortNewestFirst = true;

  Future<void> _search(String query) async {
    final q = query.trim();

    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }

    setState(() => _loading = true);

    final results = await _repo.search(
      q,
      newestFirst: _sortNewestFirst,
    );

    if (!mounted) return;

    setState(() {
      _results = results;
      _loading = false;
    });
  }

  Future<void> _deleteItem(SavedItem item) async {
    if (item.id == null) return;
    await _repo.delete(item.id!);
    _search(_queryCtrl.text);
  }

  Future<void> _editItem(SavedItem item) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddItemPage(existingItem: item),
      ),
    );

    if (result == true) {
      _search(_queryCtrl.text);
    }
  }

  void _toggleSort() {
    setState(() {
      _sortNewestFirst = !_sortNewestFirst;
    });
    _search(_queryCtrl.text);
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.search),
        actions: [
          IconButton(
            icon: Icon(
              _sortNewestFirst
                  ? Icons.arrow_downward
                  : Icons.arrow_upward,
            ),
            onPressed: _toggleSort,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _queryCtrl,
              decoration: InputDecoration(
                labelText: loc.searchLabel,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: _search,
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          Expanded(
            child: _results.isEmpty
                ? Center(
                    child: Text(loc.noResults),
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (context, index) {
                      final item = _results[index];

                      return ListTile(
                        title: Text(
                          item.ogTitle?.isNotEmpty ==
                                  true
                              ? item.ogTitle!
                              : item.url,
                        ),
                        subtitle: Text(
                            '${item.category} • ${item.platform}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ItemPreviewPage(
                                      item: item),
                            ),
                          );
                        },
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'edit') {
                              _editItem(item);
                            } else if (value ==
                                'delete') {
                              _deleteItem(item);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(loc.edit),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(loc.delete),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
