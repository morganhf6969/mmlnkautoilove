import 'package:flutter/material.dart';
import '../../data/models/saved_item.dart';

class SocialPreviewTile extends StatelessWidget {
  final SavedItem item;

  const SocialPreviewTile({
    super.key,
    required this.item,
  });

  bool get _isInstagram => item.platform == 'instagram';
  bool get _isTikTok => item.platform == 'tiktok';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          Positioned.fill(child: _buildPreview(context)),
          _buildPlatformBadge(),
          if (item.ogTitle != null) _buildTitleOverlay(),
        ],
      ),
    );
  }

  /// ===============================
  /// PREVIEW LOGIC
  /// ===============================
  Widget _buildPreview(BuildContext context) {
    if (_isInstagram) {
      return _instagramPlaceholder(context);
    }

    if (item.ogImage != null) {
      return Image.network(
        item.ogImage!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(context),
      );
    }

    return _fallback(context);
  }

  /// ===============================
  /// INSTAGRAM PLACEHOLDER (VOLUTO)
  /// ===============================
  Widget _instagramPlaceholder(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(
          Icons.play_circle_outline,
          size: 56,
          color: Colors.white70,
        ),
      ),
    );
  }

  /// ===============================
  /// FALLBACK GENERICO
  /// ===============================
  Widget _fallback(BuildContext context) {
    return Container(
      color: Theme.of(context).cardColor,
      child: const Center(
        child: Icon(
          Icons.link,
          size: 42,
          color: Colors.grey,
        ),
      ),
    );
  }

  /// ===============================
  /// TITLE OVERLAY
  /// ===============================
  Widget _buildTitleOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.75),
            ],
          ),
        ),
        child: Text(
          item.ogTitle!,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// ===============================
  /// PLATFORM BADGE
  /// ===============================
  Widget _buildPlatformBadge() {
    return Positioned(
      top: 6,
      right: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          item.platform.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
