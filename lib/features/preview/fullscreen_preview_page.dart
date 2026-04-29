import 'package:flutter/material.dart';
import 'package:memolink/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/models/saved_item.dart';

class FullscreenPreviewPage extends StatelessWidget {
  final SavedItem item;

  const FullscreenPreviewPage({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          item.platform.toUpperCase(),
          style: const TextStyle(fontSize: 14),
        ),
      ),
      body: GestureDetector(
        onTap: _openExternal,
        child: Stack(
          children: [
            // BACKGROUND
            Positioned.fill(
              child: _buildBackground(),
            ),

            // OVERLAY INFO
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.ogTitle != null)
                      Text(
                        item.ogTitle!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _openExternal,
                      icon: const Icon(Icons.open_in_new),
                      label: Text(AppLocalizations.of(context)!.openContent),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===============================
  /// BACKGROUND
  /// ===============================
  Widget _buildBackground() {
    if (item.ogImage != null) {
      return Image.network(
        item.ogImage!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return const Center(
      child: Icon(
        Icons.play_circle_fill,
        size: 96,
        color: Colors.white54,
      ),
    );
  }

  /// ===============================
  /// OPEN EXTERNAL APP
  /// ===============================
  Future<void> _openExternal() async {
    final uri = Uri.parse(item.url);

    // Prova apertura diretta app
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      // Fallback browser
      await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
    }
  }
}
