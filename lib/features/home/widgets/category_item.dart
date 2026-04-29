import 'package:flutter/material.dart';

class CategoryItem extends StatelessWidget {
  final String label;
  final int count;
  final List<Color> gradient;
  final IconData icon;
  final String? imagePath;
  final String? emoji;

  const CategoryItem({
    super.key,
    required this.label,
    required this.count,
    required this.gradient,
    required this.icon,
    this.imagePath,
    this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: _buildLeading(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '$count link',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildLeading() {
    // 1. Se c'è un'immagine PNG (asset), mostra quella
    if (imagePath != null) {
      return Center(
        child: Image.asset(
          imagePath!,
          width: 48,
          height: 48,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => Icon(icon, color: Colors.grey),
        ),
      );
    }
    // 2. Se c'è una Emoji, mostra quella
    if (emoji != null) {
      return Center(
        child: Text(
          emoji!,
          style: const TextStyle(fontSize: 48),
        ),
      );
    }
    // 3. Fallback sull'icona standard
    return Icon(icon, size: 48, color: Colors.grey.shade400);
  }
}