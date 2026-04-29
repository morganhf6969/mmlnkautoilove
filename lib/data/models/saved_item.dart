class SavedItem {
  final int? id;
  final String url;
  final String platform;
  final String category;
  final List<String> hashtags;
  final DateTime createdAt;

  // 🆕 OpenGraph
  final String? ogTitle;
  final String? ogImage;

  SavedItem({
    this.id,
    required this.url,
    required this.platform,
    required this.category,
    required this.hashtags,
    required this.createdAt,
    this.ogTitle,
    this.ogImage,
  });

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'url': url,
      'platform': platform,
      'category': category,
      'hashtags': hashtags.join(','),
      'created_at': createdAt.toIso8601String(),
      'og_title': ogTitle,
      'og_image': ogImage,
    };

    if (id != null) {
      map['id'] = id;
    }

    return map;
  }

  factory SavedItem.fromMap(Map<String, dynamic> map) {
    return SavedItem(
      id: map['id'] as int?,
      url: map['url'],
      platform: map['platform'],
      category: map['category'],
      hashtags: map['hashtags'] != null && map['hashtags'].toString().isNotEmpty
          ? map['hashtags'].toString().split(',')
          : [],
      createdAt: DateTime.parse(map['created_at']),
      ogTitle: map['og_title'],
      ogImage: map['og_image'],
    );
  }
}
