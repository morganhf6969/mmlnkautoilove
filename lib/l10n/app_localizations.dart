import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('it')
  ];

  /// No description provided for @appTitle.
  ///
  /// In it, this message translates to:
  /// **'MemoLink'**
  String get appTitle;

  /// No description provided for @appVersion.
  ///
  /// In it, this message translates to:
  /// **'MemoLink v4.0.2'**
  String get appVersion;

  /// No description provided for @search.
  ///
  /// In it, this message translates to:
  /// **'Cerca'**
  String get search;

  /// No description provided for @edit.
  ///
  /// In it, this message translates to:
  /// **'Modifica'**
  String get edit;

  /// No description provided for @newCategory.
  ///
  /// In it, this message translates to:
  /// **'Nuova'**
  String get newCategory;

  /// No description provided for @settings.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get settings;

  /// No description provided for @cancel.
  ///
  /// In it, this message translates to:
  /// **'Annulla'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In it, this message translates to:
  /// **'Salva'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get delete;

  /// No description provided for @newCategoryTitle.
  ///
  /// In it, this message translates to:
  /// **'Nuova Categoria'**
  String get newCategoryTitle;

  /// No description provided for @editCategoryTitle.
  ///
  /// In it, this message translates to:
  /// **'Modifica Categoria'**
  String get editCategoryTitle;

  /// No description provided for @categoryNameHint.
  ///
  /// In it, this message translates to:
  /// **'Nome categoria'**
  String get categoryNameHint;

  /// No description provided for @openLink.
  ///
  /// In it, this message translates to:
  /// **'Apri Link'**
  String get openLink;

  /// No description provided for @premium.
  ///
  /// In it, this message translates to:
  /// **'PREMIUM'**
  String get premium;

  /// No description provided for @free.
  ///
  /// In it, this message translates to:
  /// **'FREE'**
  String get free;

  /// No description provided for @searchHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca...'**
  String get searchHint;

  /// No description provided for @upgradeToPremium.
  ///
  /// In it, this message translates to:
  /// **'Passa a Premium'**
  String get upgradeToPremium;

  /// No description provided for @upgradeSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Sblocca il limite di 10 link e molto altro!'**
  String get upgradeSubtitle;

  /// No description provided for @noResults.
  ///
  /// In it, this message translates to:
  /// **'Nessun risultato'**
  String get noResults;

  /// No description provided for @errorOpeningLink.
  ///
  /// In it, this message translates to:
  /// **'Errore nell\'apertura del link'**
  String get errorOpeningLink;

  /// No description provided for @errorSavingLink.
  ///
  /// In it, this message translates to:
  /// **'Errore durante il salvataggio'**
  String get errorSavingLink;

  /// No description provided for @limitReached.
  ///
  /// In it, this message translates to:
  /// **'Limite raggiunto'**
  String get limitReached;

  /// No description provided for @limitReachedMessage.
  ///
  /// In it, this message translates to:
  /// **'Hai raggiunto il limite di 10 link per la versione gratuita. Passa a Premium per salvare link illimitati!'**
  String get limitReachedMessage;

  /// No description provided for @becomePremium.
  ///
  /// In it, this message translates to:
  /// **'DIVENTA PREMIUM'**
  String get becomePremium;

  /// No description provided for @subscription.
  ///
  /// In it, this message translates to:
  /// **'Abbonamento'**
  String get subscription;

  /// No description provided for @premiumVersion.
  ///
  /// In it, this message translates to:
  /// **'Versione Premium'**
  String get premiumVersion;

  /// No description provided for @freeVersion.
  ///
  /// In it, this message translates to:
  /// **'Versione Free'**
  String get freeVersion;

  /// No description provided for @allBenefitsUnlocked.
  ///
  /// In it, this message translates to:
  /// **'Tutti i vantaggi sbloccati!'**
  String get allBenefitsUnlocked;

  /// No description provided for @unlimitedLinks.
  ///
  /// In it, this message translates to:
  /// **'Passa a Premium per link illimitati e altro.'**
  String get unlimitedLinks;

  /// No description provided for @restorePurchases.
  ///
  /// In it, this message translates to:
  /// **'Ripristina Acquisti'**
  String get restorePurchases;

  /// No description provided for @appearance.
  ///
  /// In it, this message translates to:
  /// **'Aspetto'**
  String get appearance;

  /// No description provided for @gridLayout.
  ///
  /// In it, this message translates to:
  /// **'Layout Griglia'**
  String get gridLayout;

  /// No description provided for @automatic.
  ///
  /// In it, this message translates to:
  /// **'Automatico'**
  String get automatic;

  /// No description provided for @columns.
  ///
  /// In it, this message translates to:
  /// **'colonne'**
  String get columns;

  /// No description provided for @dataAndSecurity.
  ///
  /// In it, this message translates to:
  /// **'Dati e Sicurezza'**
  String get dataAndSecurity;

  /// No description provided for @exportBackup.
  ///
  /// In it, this message translates to:
  /// **'Esporta Backup'**
  String get exportBackup;

  /// No description provided for @exportBackupSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Salva i tuoi link in un file'**
  String get exportBackupSubtitle;

  /// No description provided for @importBackup.
  ///
  /// In it, this message translates to:
  /// **'Importa Backup'**
  String get importBackup;

  /// No description provided for @importBackupSubtitle.
  ///
  /// In it, this message translates to:
  /// **'Ripristina link da un file'**
  String get importBackupSubtitle;

  /// No description provided for @other.
  ///
  /// In it, this message translates to:
  /// **'Altro'**
  String get other;

  /// No description provided for @helpGuide.
  ///
  /// In it, this message translates to:
  /// **'Guida all\'uso'**
  String get helpGuide;

  /// No description provided for @shareApp.
  ///
  /// In it, this message translates to:
  /// **'Condividi MemoLink'**
  String get shareApp;

  /// No description provided for @backupRestoration.
  ///
  /// In it, this message translates to:
  /// **'Ripristino dati'**
  String get backupRestoration;

  /// No description provided for @backupRestorationMessage.
  ///
  /// In it, this message translates to:
  /// **'I link esistenti verranno integrati con quelli del backup. Vuoi continuare?'**
  String get backupRestorationMessage;

  /// No description provided for @restore.
  ///
  /// In it, this message translates to:
  /// **'RIPRISTINA'**
  String get restore;

  /// No description provided for @backupSavedSuccessfully.
  ///
  /// In it, this message translates to:
  /// **'Backup salvato con successo!'**
  String get backupSavedSuccessfully;

  /// No description provided for @backupRestored.
  ///
  /// In it, this message translates to:
  /// **'Ripristino completato!'**
  String get backupRestored;

  /// No description provided for @backupError.
  ///
  /// In it, this message translates to:
  /// **'Errore backup'**
  String get backupError;

  /// No description provided for @restoreError.
  ///
  /// In it, this message translates to:
  /// **'Errore nel ripristino'**
  String get restoreError;

  /// No description provided for @operationCancelled.
  ///
  /// In it, this message translates to:
  /// **'Operazione annullata o fallita.'**
  String get operationCancelled;

  /// No description provided for @restoredSuccessfully.
  ///
  /// In it, this message translates to:
  /// **'Acquisti ripristinati con successo!'**
  String get restoredSuccessfully;

  /// No description provided for @noRestorableItems.
  ///
  /// In it, this message translates to:
  /// **'Nessun acquisto pregresso trovato.'**
  String get noRestorableItems;

  /// No description provided for @errorOperation.
  ///
  /// In it, this message translates to:
  /// **'Errore durante l\'operazione'**
  String get errorOperation;

  /// No description provided for @purchaseSuccess.
  ///
  /// In it, this message translates to:
  /// **'Grazie per il tuo acquisto! Premium Attivato.'**
  String get purchaseSuccess;

  /// No description provided for @addLink.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi link'**
  String get addLink;

  /// No description provided for @editLink.
  ///
  /// In it, this message translates to:
  /// **'Modifica link'**
  String get editLink;

  /// No description provided for @link.
  ///
  /// In it, this message translates to:
  /// **'Link'**
  String get link;

  /// No description provided for @selectCategory.
  ///
  /// In it, this message translates to:
  /// **'Seleziona Categoria'**
  String get selectCategory;

  /// No description provided for @hashtag.
  ///
  /// In it, this message translates to:
  /// **'Hashtag'**
  String get hashtag;

  /// No description provided for @hashtags.
  ///
  /// In it, this message translates to:
  /// **'Hashtag'**
  String get hashtags;

  /// No description provided for @hashtaginput.
  ///
  /// In it, this message translates to:
  /// **'Scrivi e premi spazio'**
  String get hashtaginput;

  /// No description provided for @saveLink.
  ///
  /// In it, this message translates to:
  /// **'SALVA LINK'**
  String get saveLink;

  /// No description provided for @linkDetails.
  ///
  /// In it, this message translates to:
  /// **'Dettaglio Link'**
  String get linkDetails;

  /// No description provided for @searchLabel.
  ///
  /// In it, this message translates to:
  /// **'Cerca per URL, titolo, categoria o hashtag'**
  String get searchLabel;

  /// No description provided for @noSearch.
  ///
  /// In it, this message translates to:
  /// **'Nessun link trovato'**
  String get noSearch;

  /// No description provided for @searchPage.
  ///
  /// In it, this message translates to:
  /// **'Cerca'**
  String get searchPage;

  /// No description provided for @deleteConfirm.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get deleteConfirm;

  /// No description provided for @deleteMessage.
  ///
  /// In it, this message translates to:
  /// **'Vuoi eliminare definitivamente questo link?'**
  String get deleteMessage;

  /// No description provided for @linkWithoutTitle.
  ///
  /// In it, this message translates to:
  /// **'Contenuto senza titolo'**
  String get linkWithoutTitle;

  /// No description provided for @onboardingSlide1.
  ///
  /// In it, this message translates to:
  /// **'Salva e organizza i tuoi link social in modo intelligente.'**
  String get onboardingSlide1;

  /// No description provided for @onboardingSlide2Android.
  ///
  /// In it, this message translates to:
  /// **'COME FUNZIONA SU ANDROID'**
  String get onboardingSlide2Android;

  /// No description provided for @onboardingSlide2iOS.
  ///
  /// In it, this message translates to:
  /// **'COME FUNZIONA SU iPHONE'**
  String get onboardingSlide2iOS;

  /// No description provided for @onboardingStep1.
  ///
  /// In it, this message translates to:
  /// **'Copia il link.'**
  String get onboardingStep1;

  /// No description provided for @onboardingStep2.
  ///
  /// In it, this message translates to:
  /// **'Apri MemoLink.'**
  String get onboardingStep2;

  /// No description provided for @onboardingStep3.
  ///
  /// In it, this message translates to:
  /// **'Incolla il link.'**
  String get onboardingStep3;

  /// No description provided for @onboardingStep4.
  ///
  /// In it, this message translates to:
  /// **'Scegli o crea una categoria.'**
  String get onboardingStep4;

  /// No description provided for @onboardingStep5.
  ///
  /// In it, this message translates to:
  /// **'Salva.'**
  String get onboardingStep5;

  /// No description provided for @onboardingSlide3Title.
  ///
  /// In it, this message translates to:
  /// **'Suggerimento'**
  String get onboardingSlide3Title;

  /// No description provided for @onboardingSlide3Message.
  ///
  /// In it, this message translates to:
  /// **'Usa hashtag come #marketing #ricette #idee per trovare tutto più velocemente.'**
  String get onboardingSlide3Message;

  /// No description provided for @dontShowAgain.
  ///
  /// In it, this message translates to:
  /// **'Non mostrare più questa guida'**
  String get dontShowAgain;

  /// No description provided for @start.
  ///
  /// In it, this message translates to:
  /// **'Inizia'**
  String get start;

  /// No description provided for @openContent.
  ///
  /// In it, this message translates to:
  /// **'Apri contenuto'**
  String get openContent;

  /// No description provided for @openOnFacebook.
  ///
  /// In it, this message translates to:
  /// **'Apri su Facebook'**
  String get openOnFacebook;

  /// No description provided for @openOnInstagram.
  ///
  /// In it, this message translates to:
  /// **'Apri su Instagram'**
  String get openOnInstagram;

  /// No description provided for @openOnTikTok.
  ///
  /// In it, this message translates to:
  /// **'Apri su TikTok'**
  String get openOnTikTok;

  /// No description provided for @openOnYouTube.
  ///
  /// In it, this message translates to:
  /// **'Apri su YouTube'**
  String get openOnYouTube;

  /// No description provided for @openOnX.
  ///
  /// In it, this message translates to:
  /// **'Apri su X'**
  String get openOnX;

  /// No description provided for @openWebsite.
  ///
  /// In it, this message translates to:
  /// **'Apri Sito Web'**
  String get openWebsite;

  /// No description provided for @all.
  ///
  /// In it, this message translates to:
  /// **'Tutti'**
  String get all;

  /// No description provided for @searchByTitleOrTag.
  ///
  /// In it, this message translates to:
  /// **'Cerca per titolo o #tag...'**
  String get searchByTitleOrTag;

  /// No description provided for @noLinksFound.
  ///
  /// In it, this message translates to:
  /// **'Nessun link trovato'**
  String get noLinksFound;

  /// No description provided for @newCategoryDialog.
  ///
  /// In it, this message translates to:
  /// **'Nuova categoria'**
  String get newCategoryDialog;

  /// No description provided for @editCategoryDialog.
  ///
  /// In it, this message translates to:
  /// **'Modifica categoria'**
  String get editCategoryDialog;

  /// No description provided for @selectIconLabel.
  ///
  /// In it, this message translates to:
  /// **'Seleziona icona:'**
  String get selectIconLabel;

  /// No description provided for @editLinkTitle.
  ///
  /// In it, this message translates to:
  /// **'Modifica link'**
  String get editLinkTitle;

  /// No description provided for @addLinkTitle.
  ///
  /// In it, this message translates to:
  /// **'Aggiungi link'**
  String get addLinkTitle;

  /// No description provided for @limitReachedDialog.
  ///
  /// In it, this message translates to:
  /// **'Limite raggiunto'**
  String get limitReachedDialog;

  /// No description provided for @deleteCategoryTitle.
  ///
  /// In it, this message translates to:
  /// **'Elimina Categoria'**
  String get deleteCategoryTitle;

  /// No description provided for @deleteCategoryMessage.
  ///
  /// In it, this message translates to:
  /// **'Sei sicuro di voler eliminare questa categoria? Verranno eliminati anche tutti i link al suo interno.'**
  String get deleteCategoryMessage;

  /// No description provided for @deleteLinkTitle.
  ///
  /// In it, this message translates to:
  /// **'Elimina'**
  String get deleteLinkTitle;

  /// No description provided for @deleteLinkMessage.
  ///
  /// In it, this message translates to:
  /// **'Vuoi eliminare definitivamente questo link?'**
  String get deleteLinkMessage;

  /// No description provided for @searchHintText.
  ///
  /// In it, this message translates to:
  /// **'Cerca per titolo o #tag...'**
  String get searchHintText;

  /// No description provided for @contentWithoutTitle.
  ///
  /// In it, this message translates to:
  /// **'Contenuto senza titolo'**
  String get contentWithoutTitle;

  /// No description provided for @confirmDeleteButton.
  ///
  /// In it, this message translates to:
  /// **'ELIMINA'**
  String get confirmDeleteButton;

  /// No description provided for @confirmCancelButton.
  ///
  /// In it, this message translates to:
  /// **'ANNULLA'**
  String get confirmCancelButton;

  /// No description provided for @confirmRestoreButton.
  ///
  /// In it, this message translates to:
  /// **'RIPRISTINA'**
  String get confirmRestoreButton;

  /// No description provided for @linkField.
  ///
  /// In it, this message translates to:
  /// **'Link'**
  String get linkField;

  /// No description provided for @hashtagField.
  ///
  /// In it, this message translates to:
  /// **'Hashtag'**
  String get hashtagField;

  /// No description provided for @selectCategoryLabel.
  ///
  /// In it, this message translates to:
  /// **'Seleziona Categoria'**
  String get selectCategoryLabel;

  /// No description provided for @allItems.
  ///
  /// In it, this message translates to:
  /// **'Tutti'**
  String get allItems;

  /// No description provided for @saveLinkButton.
  ///
  /// In it, this message translates to:
  /// **'SALVA LINK'**
  String get saveLinkButton;

  /// No description provided for @premiumDialogTitle.
  ///
  /// In it, this message translates to:
  /// **'Limite raggiunto'**
  String get premiumDialogTitle;

  /// No description provided for @becomePremiumButton.
  ///
  /// In it, this message translates to:
  /// **'DIVENTA PREMIUM'**
  String get becomePremiumButton;

  /// No description provided for @backupDialogTitle.
  ///
  /// In it, this message translates to:
  /// **'Ripristino dati'**
  String get backupDialogTitle;

  /// No description provided for @backupDialogMessage.
  ///
  /// In it, this message translates to:
  /// **'I link esistenti verranno integrati con quelli del backup. Vuoi continuare?'**
  String get backupDialogMessage;

  /// No description provided for @settingsTitle.
  ///
  /// In it, this message translates to:
  /// **'Impostazioni'**
  String get settingsTitle;

  /// No description provided for @subscriptionSection.
  ///
  /// In it, this message translates to:
  /// **'Abbonamento'**
  String get subscriptionSection;

  /// No description provided for @appearanceSection.
  ///
  /// In it, this message translates to:
  /// **'Aspetto'**
  String get appearanceSection;

  /// No description provided for @dataSecuritySection.
  ///
  /// In it, this message translates to:
  /// **'Dati e Sicurezza'**
  String get dataSecuritySection;

  /// No description provided for @otherSection.
  ///
  /// In it, this message translates to:
  /// **'Altro'**
  String get otherSection;

  /// No description provided for @restorePurchasesTitle.
  ///
  /// In it, this message translates to:
  /// **'Ripristina Acquisti'**
  String get restorePurchasesTitle;

  /// No description provided for @gridLayoutTitle.
  ///
  /// In it, this message translates to:
  /// **'Layout Griglia'**
  String get gridLayoutTitle;

  /// No description provided for @languageTitle.
  ///
  /// In it, this message translates to:
  /// **'Lingua / Language'**
  String get languageTitle;

  /// No description provided for @automaticDefault.
  ///
  /// In it, this message translates to:
  /// **'Automatico (Default)'**
  String get automaticDefault;

  /// No description provided for @columnsLabel.
  ///
  /// In it, this message translates to:
  /// **'colonne per riga'**
  String get columnsLabel;

  /// No description provided for @exportBackupTitle.
  ///
  /// In it, this message translates to:
  /// **'Esporta Backup'**
  String get exportBackupTitle;

  /// No description provided for @importBackupTitle.
  ///
  /// In it, this message translates to:
  /// **'Importa Backup'**
  String get importBackupTitle;

  /// No description provided for @helpGuideTitle.
  ///
  /// In it, this message translates to:
  /// **'Guida all\'uso'**
  String get helpGuideTitle;

  /// No description provided for @shareAppTitle.
  ///
  /// In it, this message translates to:
  /// **'Condividi MemoLink'**
  String get shareAppTitle;

  /// No description provided for @onboardingStep6Android.
  ///
  /// In it, this message translates to:
  /// **'Apri Chrome o un\'altra app.'**
  String get onboardingStep6Android;

  /// No description provided for @onboardingStep7Android.
  ///
  /// In it, this message translates to:
  /// **'Tocca Condividi.'**
  String get onboardingStep7Android;

  /// No description provided for @onboardingStep8Android.
  ///
  /// In it, this message translates to:
  /// **'Seleziona MemoLink.'**
  String get onboardingStep8Android;

  /// No description provided for @onboardingStep9Android.
  ///
  /// In it, this message translates to:
  /// **'L\'app si apre automaticamente con il link pronto.'**
  String get onboardingStep9Android;

  /// No description provided for @onboardingStep10Android.
  ///
  /// In it, this message translates to:
  /// **'Scegli una categoria e salva.'**
  String get onboardingStep10Android;

  /// No description provided for @onboardingStep6iOS.
  ///
  /// In it, this message translates to:
  /// **'Apri Safari o un\'altra app.'**
  String get onboardingStep6iOS;

  /// No description provided for @onboardingStep7iOS.
  ///
  /// In it, this message translates to:
  /// **'Tocca Condividi.'**
  String get onboardingStep7iOS;

  /// No description provided for @onboardingStep8iOS.
  ///
  /// In it, this message translates to:
  /// **'Seleziona MemoLink.'**
  String get onboardingStep8iOS;

  /// No description provided for @onboardingStep9iOS.
  ///
  /// In it, this message translates to:
  /// **'Apri MemoLink manualmente.'**
  String get onboardingStep9iOS;

  /// No description provided for @onboardingStep10iOS.
  ///
  /// In it, this message translates to:
  /// **'Il link è già pronto nella pagina di inserimento.'**
  String get onboardingStep10iOS;

  /// No description provided for @onboardingStep11iOS.
  ///
  /// In it, this message translates to:
  /// **'Scegli una categoria e salva.'**
  String get onboardingStep11iOS;

  /// No description provided for @onboardingTip.
  ///
  /// In it, this message translates to:
  /// **'Suggerimento'**
  String get onboardingTip;

  /// No description provided for @onboardingTipMessage.
  ///
  /// In it, this message translates to:
  /// **'Usa hashtag come #marketing #ricette #idee per trovare tutto più velocemente.'**
  String get onboardingTipMessage;

  /// No description provided for @onboardingSlide4Title.
  ///
  /// In it, this message translates to:
  /// **'Condividi & Nascondi'**
  String get onboardingSlide4Title;

  /// No description provided for @onboardingSlide4ShareLabel.
  ///
  /// In it, this message translates to:
  /// **'CONDIVIDI UNA CATEGORIA'**
  String get onboardingSlide4ShareLabel;

  /// No description provided for @onboardingSlide4ShareStep1.
  ///
  /// In it, this message translates to:
  /// **'Tieni premuto su una categoria.'**
  String get onboardingSlide4ShareStep1;

  /// No description provided for @onboardingSlide4ShareStep2.
  ///
  /// In it, this message translates to:
  /// **'Tocca \"Condividi categoria\".'**
  String get onboardingSlide4ShareStep2;

  /// No description provided for @onboardingSlide4ShareStep3.
  ///
  /// In it, this message translates to:
  /// **'Copia il link generato e invialo a chi vuoi.'**
  String get onboardingSlide4ShareStep3;

  /// No description provided for @onboardingSlide4ShareStep4.
  ///
  /// In it, this message translates to:
  /// **'Chi lo riceve può importare la categoria nella propria app.'**
  String get onboardingSlide4ShareStep4;

  /// No description provided for @onboardingSlide4HideLabel.
  ///
  /// In it, this message translates to:
  /// **'NASCONDI UNA CATEGORIA'**
  String get onboardingSlide4HideLabel;

  /// No description provided for @onboardingSlide4HideStep1.
  ///
  /// In it, this message translates to:
  /// **'Tieni premuto su una categoria.'**
  String get onboardingSlide4HideStep1;

  /// No description provided for @onboardingSlide4HideStep2.
  ///
  /// In it, this message translates to:
  /// **'Tocca \"Nascondi\".'**
  String get onboardingSlide4HideStep2;

  /// No description provided for @onboardingSlide4HideStep3.
  ///
  /// In it, this message translates to:
  /// **'La prima volta, crea un codice di accesso (min. 4 cifre).'**
  String get onboardingSlide4HideStep3;

  /// No description provided for @onboardingSlide4HideStep4.
  ///
  /// In it, this message translates to:
  /// **'La categoria sparisce dalla schermata principale.'**
  String get onboardingSlide4HideStep4;

  /// No description provided for @onboardingSlide4HideStep5.
  ///
  /// In it, this message translates to:
  /// **'Per ripristinarla: Impostazioni → Categorie nascoste.'**
  String get onboardingSlide4HideStep5;

  /// No description provided for @startButton.
  ///
  /// In it, this message translates to:
  /// **'Inizia'**
  String get startButton;

  /// No description provided for @setupCategoryMessage.
  ///
  /// In it, this message translates to:
  /// **'Seleziona categoria'**
  String get setupCategoryMessage;

  /// No description provided for @newCategoryButtonLabel.
  ///
  /// In it, this message translates to:
  /// **'Nuova'**
  String get newCategoryButtonLabel;

  /// No description provided for @categorySearchHint.
  ///
  /// In it, this message translates to:
  /// **'Cerca...'**
  String get categorySearchHint;

  /// No description provided for @linkDetailsTitle.
  ///
  /// In it, this message translates to:
  /// **'Dettaglio Link'**
  String get linkDetailsTitle;

  /// No description provided for @errorDuringOperation.
  ///
  /// In it, this message translates to:
  /// **'Errore durante l\'operazione'**
  String get errorDuringOperation;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
