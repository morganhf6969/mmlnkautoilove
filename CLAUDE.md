# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MemoLink is a Flutter app for saving and organizing social media links intelligently. The app supports categorization, search, hashtag filtering, OpenGraph metadata extraction, and in-app premium features via RevenueCat.

**Version:** 4.0.0
**Platforms:** iOS, Android, Web
**Internationalization:** Italian (it), English (en)
**State Management:** ValueNotifier for locale, direct StateManager usage in pages
**Database:** SQLite (sqflite)
**In-App Purchases:** RevenueCat (Purchases)

---

## Project Structure

```
lib/
├── main.dart                    # App entry point, locale initialization, RevenueCat setup
├── app/
│   └── routes.dart             # Static routing table (home, addItem routes)
├── core/
│   ├── constants/categories.dart # Category definitions
│   ├── locale_provider.dart     # Locale management
│   └── services/                # Platform-specific utilities
│       ├── backup_service.dart
│       ├── share_service.dart
│       ├── haptic_service.dart
│       └── *_sound_service.dart
├── data/
│   ├── models/
│   │   └── saved_item.dart     # SavedItem (url, platform, category, hashtags, og metadata)
│   ├── database/
│   │   ├── app_database.dart   # Singleton DB access, schema initialization
│   │   ├── saved_item_dao.dart
│   │   └── category_dao.dart
│   └── repositories/
│       └── saved_item_repository.dart # CRUD logic, search, backup/import
├── features/
│   ├── home/                    # Main screen (category grid, edit mode, search)
│   ├── list/
│   │   └── category_list_page.dart # Items in a category
│   ├── add/
│   │   └── add_item_page.dart   # Add new item with URL/platform detection
│   ├── preview/
│   │   ├── item_preview_page.dart
│   │   ├── instagram_preview.dart
│   │   └── tiktok_preview.dart
│   ├── search/
│   │   └── search_page.dart     # Search UI
│   ├── settings/
│   │   └── settings_page.dart
│   ├── onboarding/
│   │   └── onboarding_page.dart
│   └── splash/
│       └── splash_page.dart
├── l10n/                         # Localizations (auto-generated)
├── app/theme.dart               # Color schemes, Material3 config
└── theme_controller.dart        # Theme state (light/dark toggle)
```

---

## Key Architecture Patterns

### Data Layer
- **SavedItemRepository**: Single source for item CRUD, search, and backup operations
- **AppDatabase**: Lazily-initialized SQLite singleton with schema initialization
- **DAOs** (CategoryDao, SavedItemDao): Direct DB access wrappers

### Feature Structure
- Pages are typically StatefulWidget with direct repository instantiation
- No formal state management framework (no Provider, Riverpod)—each page manages its own state
- Search queries use SQLite LIKE across og_title, hashtags, url, and category_name

### Localization
- ValueNotifier<Locale> for app-wide locale state (main.dart, line 12)
- AppLocalizations generated from l10n.yaml (intl-based)
- Default locale: Italian (it)

### Platform Integration
- MethodChannel 'com.memolink.sharing/channel' for native deep linking
- RevenueCat setup for iOS and Android in main.dart
- Share, file picker, and haptic feedback services abstracted per platform

---

## Common Commands

```bash
# Get dependencies
flutter pub get

# Analyze code (lint check)
flutter analyze

# Run app on connected device/emulator
flutter run

# Run app in debug mode (verbose)
flutter run -v

# Run app in release mode
flutter run --release

# Generate localizations (after editing l10n.yaml or .arb files)
flutter gen-l10n

# Generate launcher icons (from assets/app_icon.png)
flutter pub run flutter_launcher_icons

# Format code
dart format lib/

# Generate build runner outputs if needed
flutter pub run build_runner build --delete-conflicting-outputs

# Build APK (Android)
flutter build apk --release

# Build iOS IPA
flutter build ios --release
```

---

## Working with SavedItems

The core model is `SavedItem` in `lib/data/models/saved_item.dart`:
- **url**: The link being saved
- **platform**: Detected platform (Instagram, TikTok, YouTube, manual, etc.)
- **category**: Category name (must match a category in DB)
- **hashtags**: Extracted from URL or user input
- **createdAt**: ISO 8601 timestamp
- **ogTitle**: OpenGraph title (meta tag)
- **ogImage**: OpenGraph image (meta tag)

### Adding Items
In `AddItemPage`, items are saved via `SavedItemRepository.save()`, which enforces:
- Free tier: max 10 items (checked in repository)
- Premium: unlimited items

### Search & Filter
`SavedItemRepository.search(query)` matches across:
- og_title, hashtags, url, category_name (case-insensitive LIKE)
- Results ordered by created_at DESC by default

### Database Schema
Categories and items are linked by foreign key (category_id). Categories are initialized in `AppDatabase` and managed via `CategoryDao`.

---

## Adding New Features (V4)

**Workflow:**
1. Add model to `lib/data/models/`
2. Add repository methods to `SavedItemRepository` or new repository
3. Create feature page in `lib/features/`
4. Add route in `lib/app/routes.dart` if needed
5. Update `AppRoutes.routes` and link from navigation

**Best Practices:**
- Keep pages as self-contained StatefulWidgets
- Use `SavedItemRepository` as the single source of truth for data
- Extract widgets for reusable components into `widgets/` subdirs
- Use `.og_title` and `.og_image` for display when available
- Remember to handle premium gating in repository layer

---

## Testing Notes

- No test/ directory currently; add unit and widget tests to `test/` as needed
- Key test targets: repository methods, model serialization, database operations

---

## Build & Deployment

- **Android**: Signed via Gradle keystore; RevenueCat key in main.dart
- **iOS**: Built via Xcode project in ios/; share extension in `MemoLinkShare/`
- **Versioning**: Update pubspec.yaml version and build number before release
