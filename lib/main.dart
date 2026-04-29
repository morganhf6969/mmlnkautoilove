import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:memolink/l10n/app_localizations.dart';
import 'app/routes.dart';
import 'data/models/saved_item.dart';
import 'data/repositories/saved_item_repository.dart';
import 'features/onboarding/onboarding_page.dart';

// Global locale notifier
final ValueNotifier<Locale> localeNotifier = ValueNotifier(const Locale('it'));

Future<void> _loadLocale() async {
  final prefs = await SharedPreferences.getInstance();
  final code = prefs.getString('locale') ?? 'it';
  localeNotifier.value = Locale(code);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved locale
  await _loadLocale();

  final prefs = await SharedPreferences.getInstance();
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  bool isPremium = false;

  try {
    await Purchases.setLogLevel(LogLevel.debug);

    if (Platform.isIOS) {
      await Purchases.configure(
        PurchasesConfiguration('appl_qHhRGLmmtaCSLkraPnBHdzhvUoU'),
      );
    } else if (Platform.isAndroid) {
      await Purchases.configure(
        PurchasesConfiguration('goog_SpagjfRrZRAhkmUulHgBtyFjqgr'),
      );
    }

    CustomerInfo customerInfo = await Purchases.getCustomerInfo();
    isPremium = customerInfo.entitlements.all['Memolink Premium']?.isActive ?? false;
    await prefs.setBool('is_premium', isPremium);
  } catch (e) {
    isPremium = prefs.getBool('is_premium') ?? false;
  }

  runApp(MemoLinkApp(
    showOnboarding: !onboardingCompleted,
    isPremium: isPremium,
  ));
}

class MemoLinkApp extends StatefulWidget {
  final bool showOnboarding;
  final bool isPremium;

  const MemoLinkApp({
    super.key,
    required this.showOnboarding,
    required this.isPremium,
  });

  @override
  State<MemoLinkApp> createState() => _MemoLinkAppState();
}

class _MemoLinkAppState extends State<MemoLinkApp> {
  StreamSubscription? _deepLinkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    // Link che ha aperto l'app da freddo
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) _handleDeepLink(initial);
    } catch (_) {}

    // Link mentre l'app è in background/foreground
    _deepLinkSubscription = _appLinks.uriLinkStream.listen(
      _handleDeepLink,
      onError: (_) {},
    );
  }

  void _handleDeepLink(Uri uri) {
    // Gestisce sia memolink://import/{id} (custom scheme)
    // sia https://memolink.info/import/{id} (Universal Link / App Link)
    String? id;

    if (uri.scheme == 'memolink' && uri.host == 'import') {
      id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if ((uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host == 'memolink.info' &&
        uri.pathSegments.length >= 2 &&
        uri.pathSegments[0] == 'import') {
      id = uri.pathSegments[1];
    }

    if (id == null || id.isEmpty) return;
    _fetchAndImport(id);
  }

  Future<void> _fetchAndImport(String id) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.memolink.info/share/$id'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final payload = jsonDecode(
          jsonDecode(response.body)['payload'] as String
        ) as Map<String, dynamic>;
        _showImportDialog(payload);
      } else if (response.statusCode == 410) {
        _showErrorDialog('Il link è scaduto (validità 24 ore).');
      } else {
        _showErrorDialog('Link non valido o già eliminato.');
      }
    } catch (_) {
      _showErrorDialog('Impossibile raggiungere il server.');
    }
  }

  void _showErrorDialog(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _navigatorKey.currentContext;
      if (ctx == null) return;
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text('Importazione fallita'),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(_),
                child: const Text('OK')),
          ],
        ),
      );
    });
  }

  void _showImportDialog(Map<String, dynamic> payload) {
    final category = payload['category'] as String? ?? '';
    final rawItems = payload['items'] as List<dynamic>? ?? [];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _navigatorKey.currentContext;
      if (ctx == null) return;
      showDialog(
        context: ctx,
        builder: (_) => AlertDialog(
          title: const Text('Importa categoria'),
          content: Text(
              'Vuoi importare la categoria "$category" con ${rawItems.length} link?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(_),
                child: const Text('Annulla')),
            TextButton(
              onPressed: () async {
                Navigator.pop(_);
                final repo = SavedItemRepository();
                for (final raw in rawItems) {
                  final m = raw as Map<String, dynamic>;
                  await repo.save(SavedItem(
                    url: m['url'] ?? '',
                    platform: m['platform'] ?? 'manual',
                    category: category,
                    hashtags: (m['hashtags'] as List<dynamic>?)
                            ?.map((e) => e.toString())
                            .toList() ??
                        [],
                    createdAt: DateTime.now(),
                    ogTitle: m['ogTitle'],
                    ogImage: m['ogImage'],
                  ));
                }
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Categoria "$category" importata con successo!')),
                );
              },
              child: const Text('Importa',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    });
  }

  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: localeNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          title: 'MemoLink',
          debugShowCheckedModeBanner: false,
          navigatorKey: _navigatorKey,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('it'),
            Locale('en'),
            Locale('fr'),
            Locale('es'),
          ],
          locale: locale,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'Poppins',
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          initialRoute: widget.showOnboarding ? '/onboarding' : AppRoutes.home,
          routes: {
            '/onboarding': (_) => const OnboardingPage(),
            ...AppRoutes.routes,
          },
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
              child: child!,
            );
          },
        );
      },
    );
  }
}
