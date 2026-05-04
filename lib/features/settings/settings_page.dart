import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:memolink/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../data/repositories/saved_item_repository.dart';
import '../onboarding/onboarding_page.dart';
import '../../main.dart' show localeNotifier;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SavedItemRepository _repository = SavedItemRepository();
  bool _isLoading = false;
  int? _columns;
  bool _isPremium = false;
  String _appVersion = '';
  String _userId = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    String userId = '';
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      userId = customerInfo.originalAppUserId;
    } catch (_) {}
    if (mounted) {
      setState(() {
        _appVersion = 'MemoLink v${info.version}';
        _userId = userId;
      });
    }
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    bool premiumStatus = false;
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      // Utilizzo dell'ID esatto registrato su RevenueCat
      premiumStatus = customerInfo.entitlements.all['Memolink Premium']?.isActive ?? false;
      await prefs.setBool('is_premium', premiumStatus);
    } catch (e) {
      premiumStatus = prefs.getBool('is_premium') ?? false;
    }

    setState(() {
      _columns = prefs.getInt('grid_columns');
      _isPremium = premiumStatus;
    });
  }

  Future<void> _saveColumnsSetting(int? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove('grid_columns');
    } else {
      await prefs.setInt('grid_columns', value);
    }
    setState(() {
      _columns = value;
    });
  }

  Future<void> _handlePremiumAction() async {
    if (_isPremium) return;

    setState(() => _isLoading = true);
    try {
      // Mostra il Paywall predefinito di RevenueCat
      // Nota: presentPaywallIfNeeded usa l'ID dell'Offering, di solito "default"
      final paywallResult = await RevenueCatUI.presentPaywallIfNeeded("Memolink Premium");
      
      if (paywallResult == PaywallResult.purchased || paywallResult == PaywallResult.restored) {
        await _loadSettings();
        _showSnack('Grazie per il tuo acquisto! Premium Attivato.');
      }
    } catch (e) {
      _showSnack('Errore durante l\'operazione: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    try {
      CustomerInfo restoredInfo = await Purchases.restorePurchases();
      bool premiumActive = restoredInfo.entitlements.all['Memolink Premium']?.isActive ?? false;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_premium', premiumActive);
      
      setState(() => _isPremium = premiumActive);
      
      if (premiumActive) {
        _showSnack('Acquisti ripristinati con successo!');
      } else {
        _showSnack('Nessun acquisto pregresso trovato.');
      }
    } catch (e) {
      _showSnack('Errore nel ripristino: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _createBackup() async {
    // Dialog di scelta: solo link oppure link + file
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cosa vuoi includere nel backup?'),
        content: const Text(
          'Puoi salvare solo i link e le categorie (file leggero) oppure includere anche tutti i file dell\'Archivio file (file più pesante).',
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.link_rounded),
                label: const Text('Solo link e categorie'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, 'links'),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.folder_zip_rounded),
                label: const Text('Link + file dell\'Archivio'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey.shade700,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, 'full'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Annulla'),
              ),
            ],
          ),
        ],
      ),
    );

    if (choice == null) return;

    setState(() => _isLoading = true);
    try {
      final String? result = choice == 'full'
          ? await _repository.exportBackupWithFiles()
          : await _repository.exportBackup();
      if (result != null) {
        _showSnack('Backup salvato con successo!');
      }
    } catch (e) {
      _showSnack('Errore backup: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _hashPin(String pin) => sha256.convert(utf8.encode(pin)).toString();

  Future<void> _showHiddenCategoriesAccess() async {
    final prefs = await SharedPreferences.getInstance();
    final storedHash = prefs.getString('hidden_pin');
    if (storedHash == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna categoria nascosta.')),
      );
      return;
    }

    final pinCtrl = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Inserisci codice'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: pinCtrl,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Codice',
                  border: OutlineInputBorder(),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annulla')),
            TextButton(
              onPressed: () {
                if (_hashPin(pinCtrl.text) != storedHash) {
                  setStateDialog(() => error = 'Codice errato');
                  return;
                }
                Navigator.pop(ctx);
                _showHiddenCategoriesList(prefs);
              },
              child: const Text('Accedi', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showHiddenCategoriesList(SharedPreferences prefs) async {
    final hidden = prefs.getStringList('hidden_categories') ?? [];
    if (hidden.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nessuna categoria nascosta.')),
      );
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text('Categorie nascoste'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: hidden.length,
              itemBuilder: (_, i) => ListTile(
                title: Text(hidden[i]),
                trailing: TextButton(
                  onPressed: () async {
                    hidden.removeAt(i);
                    await prefs.setStringList('hidden_categories', hidden);
                    setStateDialog(() {});
                    if (hidden.isEmpty) Navigator.pop(ctx);
                  },
                  child: const Text('Ripristina', style: TextStyle(color: Colors.green)),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Chiudi')),
          ],
        ),
      ),
    );
  }

  Future<void> _restoreBackup() async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(loc.backupRestoration),
        content: Text(loc.backupRestorationMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(loc.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.restore, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    setState(() => _isLoading = true);

    try {
      final success = await _repository.importBackup();
      if (success) {
        if (mounted) {
          _showSnack('Ripristino completato!');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) Navigator.pop(context, true); 
          });
        }
      } else {
        _showSnack('Operazione annullata o fallita.');
      }
    } catch (e) {
      _showSnack('Errore ripristino: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating)
    );
  }

  String _getLanguageLabel(String languageCode) {
    switch (languageCode) {
      case 'it':
        return '🇮🇹 Italiano';
      case 'en':
        return '🇬🇧 English';
      case 'fr':
        return '🇫🇷 Français';
      case 'es':
        return '🇪🇸 Español';
      default:
        return '🇮🇹 Italiano';
    }
  }

  Future<void> _setLocale(String languageCode) async {
    final locale = Locale(languageCode);
    localeNotifier.value = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', languageCode);
    if (mounted) {
      setState(() {});
    }
  }

  void _showLanguagePicker() {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          ListTile(
            title: const Text('🇮🇹 Italiano'),
            onTap: () {
              _setLocale('it');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('🇬🇧 English'),
            onTap: () {
              _setLocale('en');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('🇫🇷 Français'),
            onTap: () {
              _setLocale('fr');
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: const Text('🇪🇸 Español'),
            onTap: () {
              _setLocale('es');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(loc.settingsTitle, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSectionTitle(loc.subscription),
              _buildSettingsCard([
                ListTile(
                  leading: Icon(
                    _isPremium ? Icons.stars_rounded : Icons.star_outline_rounded, 
                    color: _isPremium ? Colors.amber : Colors.grey
                  ),
                  title: Text(_isPremium ? loc.premiumVersion : loc.freeVersion),
                  subtitle: Text(
                    _isPremium
                      ? loc.allBenefitsUnlocked
                      : loc.unlimitedLinks,
                    style: TextStyle(
                      color: _isPremium ? Colors.green : Colors.orange.shade800,
                      fontWeight: _isPremium ? FontWeight.bold : FontWeight.normal
                    ),
                  ),
                  trailing: _isPremium 
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.chevron_right),
                  onTap: _handlePremiumAction,
                ),
                if (!_isPremium) ...[
                  const Divider(height: 0, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.refresh_rounded, color: Colors.blueGrey),
                    title: Text(loc.restorePurchasesTitle),
                    onTap: _restorePurchases,
                  ),
                ]
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle(loc.appearance),
              _buildSettingsCard([
                ListTile(
                  leading: const Icon(Icons.grid_view_rounded, color: Colors.black87),
                  title: Text(loc.gridLayoutTitle),
                  subtitle: Text(_columns == null ? loc.automatic : '${_columns} ${loc.columns}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showColumnPicker,
                ),
                const Divider(height: 0, indent: 56),
                ListTile(
                  leading: const Icon(Icons.language_rounded, color: Colors.blue),
                  title: Text(loc.languageTitle),
                  subtitle: Text(_getLanguageLabel(localeNotifier.value.languageCode)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showLanguagePicker,
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('Privacy'),
              _buildSettingsCard([
                ListTile(
                  leading: const Icon(Icons.visibility_off_rounded, color: Colors.deepPurple),
                  title: const Text('Categorie nascoste'),
                  subtitle: const Text('Visualizza e ripristina le categorie nascoste'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _showHiddenCategoriesAccess,
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle(loc.dataAndSecurity),
              _buildSettingsCard([
                ListTile(
                  leading: const Icon(Icons.backup_rounded, color: Colors.blue),
                  title: Text(loc.exportBackup),
                  subtitle: Text(loc.exportBackupSubtitle),
                  onTap: _createBackup,
                ),
                const Divider(height: 0, indent: 56),
                ListTile(
                  leading: const Icon(Icons.restore_rounded, color: Colors.orange),
                  title: Text(loc.importBackup),
                  subtitle: Text(loc.importBackupSubtitle),
                  onTap: _restoreBackup,
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle(loc.other),
              _buildSettingsCard([
                ListTile(
                  leading: const Icon(Icons.help_outline_rounded, color: Colors.purple),
                  title: Text(loc.helpGuide),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingPage(isGuide: true))),
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('Informazioni'),
              _buildSettingsCard([
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: Colors.blueGrey),
                  title: const Text('Versione app'),
                  subtitle: Text(_appVersion.isNotEmpty ? _appVersion : '—'),
                ),
                if (_userId.isNotEmpty) ...[
                  const Divider(height: 0, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.fingerprint_rounded, color: Colors.blueGrey),
                    title: const Text('ID cliente'),
                    subtitle: Text(
                      _userId,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _userId));
                        _showSnack('ID copiato negli appunti');
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copia'),
                    ),
                  ),
                ],
              ]),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black12,
              child: const Center(child: CircularProgressIndicator(color: Colors.black)),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(children: children),
    );
  }

  void _showColumnPicker() {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
          ListTile(title: Text(loc.automaticDefault), onTap: () { _saveColumnsSetting(null); Navigator.pop(context); }),
          for (int i = 2; i <= 5; i++)
            ListTile(title: Text('$i ${loc.columnsLabel}'), onTap: () { _saveColumnsSetting(i); Navigator.pop(context); }),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}