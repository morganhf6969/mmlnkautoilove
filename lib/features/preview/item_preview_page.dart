import 'package:flutter/material.dart';
import 'package:memolink/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
// Se hai font_awesome_flutter installato usa quello, altrimenti ho usato icone di sistema simili
import '../../data/models/saved_item.dart';

class ItemPreviewPage extends StatelessWidget {
  final SavedItem item;

  const ItemPreviewPage({super.key, required this.item});

  // Funzione per decidere Icona, Colore e Testo in base alla piattaforma
  Map<String, dynamic> _getPlatformDetails(AppLocalizations loc) {
    final url = item.url.toLowerCase();
    if (url.contains('facebook.com') || url.contains('fb.watch')) {
      return {'icon': Icons.facebook, 'color': const Color(0xFF1877F2), 'label': loc.openOnFacebook};
    } else if (url.contains('instagram.com')) {
      return {'icon': Icons.camera_alt, 'color': const Color(0xFFE4405F), 'label': loc.openOnInstagram};
    } else if (url.contains('tiktok.com')) {
      return {'icon': Icons.music_note, 'color': const Color(0xFF000000), 'label': loc.openOnTikTok};
    } else if (url.contains('youtube.com') || url.contains('youtu.be')) {
      return {'icon': Icons.play_circle_fill, 'color': const Color(0xFFFF0000), 'label': loc.openOnYouTube};
    } else if (url.contains('x.com') || url.contains('twitter.com')) {
      return {'icon': Icons.close, 'color': const Color(0xFF000000), 'label': loc.openOnX};
    } else {
      return {'icon': Icons.language, 'color': Colors.blueGrey, 'label': loc.openWebsite};
    }
  }

  Future<void> _openLink() async {
    final uri = Uri.tryParse(item.url);
    if (uri == null) return;

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final platform = _getPlatformDetails(loc);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.linkDetails),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Immagine Anteprima
            if (item.ogImage != null && item.ogImage!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  item.ogImage!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 220,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image, size: 50),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Titolo del contenuto
            Text(
              item.ogTitle?.isNotEmpty == true ? item.ogTitle! : loc.linkWithoutTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            
            const SizedBox(height: 24),

            // BOTTONE SOCIAL DINAMICO
            Center(
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _openLink,
                      icon: Icon(platform['icon'], size: 28),
                      label: Text(
                        platform['label'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: platform['color'],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Elenco Hashtag sotto al bottone
                  if (item.hashtags.isNotEmpty)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: item.hashtags.map((h) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Text(
                              '#$h',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}