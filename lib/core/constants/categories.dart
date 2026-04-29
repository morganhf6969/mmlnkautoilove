import 'package:flutter/material.dart';
import 'package:memolink/l10n/app_localizations.dart';

class AppCategory {
  final String label;
  final IconData icon;
  final Color color;

  const AppCategory(this.label, this.icon, this.color);
}

const List<AppCategory> appCategories = [
  AppCategory('Cucina', Icons.restaurant, Colors.orange),
  AppCategory('Tecnologia', Icons.computer, Colors.blue),
  AppCategory('Arte', Icons.palette, Colors.purple),
  AppCategory('Musica', Icons.music_note, Colors.green),
  AppCategory('Divertente', Icons.emoji_emotions, Colors.red),
  AppCategory('Luoghi', Icons.place, Colors.teal),
  AppCategory('Moda', Icons.checkroom, Colors.pink),
  AppCategory('Altro', Icons.more_horiz, Colors.blueGrey),
  AppCategory('I ❤️ Abitini', Icons.checkroom, Colors.red),
];

/// Categorie di default che non possono essere cancellate dall'utente.
const Set<String> nonDeletableCategories = {
  'Cucina',
  'Tecnologia',
  'Arte',
  'Musica',
  'Divertente',
  'Luoghi',
  'Moda',
  'I ❤️ Abitini',
};

const Map<String, Map<String, String>> _categoryTranslations = {
  'en': {
    'Cucina': 'Kitchen',
    'Tecnologia': 'Technology',
    'Arte': 'Art',
    'Musica': 'Music',
    'Divertente': 'Fun',
    'Luoghi': 'Places',
    'Moda': 'Fashion',
    'Altro': 'Other',
    'I ❤️ Abitini': 'I ❤️ Dresses',
  },
  'it': {
    'Cucina': 'Cucina',
    'Tecnologia': 'Tecnologia',
    'Arte': 'Arte',
    'Musica': 'Musica',
    'Divertente': 'Divertente',
    'Luoghi': 'Luoghi',
    'Moda': 'Moda',
    'Altro': 'Altro',
    'I ❤️ Abitini': 'I ❤️ Abitini',
  },
  'fr': {
    'Cucina': 'Cuisine',
    'Tecnologia': 'Technologie',
    'Arte': 'Art',
    'Musica': 'Musique',
    'Divertente': 'Amusant',
    'Luoghi': 'Lieux',
    'Moda': 'Mode',
    'Altro': 'Autre',
    'I ❤️ Abitini': 'I ❤️ Robes',
  },
  'es': {
    'Cucina': 'Cocina',
    'Tecnologia': 'Tecnología',
    'Arte': 'Arte',
    'Musica': 'Música',
    'Divertente': 'Divertido',
    'Luoghi': 'Lugares',
    'Moda': 'Moda',
    'Altro': 'Otro',
    'I ❤️ Abitini': 'I ❤️ Vestidos',
  },
};

/// Restituisce il nome localizzato di una categoria di default.
/// Le categorie create dall'utente vengono restituite invariate.
String localizeDefaultCategory(String name, BuildContext context) {
  final String locale = AppLocalizations.of(context)?.localeName ?? 'it';
  return _categoryTranslations[locale]?[name] ?? name;
}
