import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

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
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In fr, this message translates to:
  /// **'Gestion Boutique GN'**
  String get appName;

  /// No description provided for @navDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau'**
  String get navDashboard;

  /// No description provided for @navProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get navProducts;

  /// No description provided for @navSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get navSales;

  /// No description provided for @navExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Depenses'**
  String get navExpenses;

  /// No description provided for @navClients.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get navClients;

  /// No description provided for @navInvoices.
  ///
  /// In fr, this message translates to:
  /// **'Factures'**
  String get navInvoices;

  /// No description provided for @navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @navSettings.
  ///
  /// In fr, this message translates to:
  /// **'Parametres'**
  String get navSettings;

  /// No description provided for @pageDashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get pageDashboard;

  /// No description provided for @pageProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get pageProducts;

  /// No description provided for @pageSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get pageSales;

  /// No description provided for @pageExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Depenses'**
  String get pageExpenses;

  /// No description provided for @pageClients.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get pageClients;

  /// No description provided for @pageInvoices.
  ///
  /// In fr, this message translates to:
  /// **'Factures'**
  String get pageInvoices;

  /// No description provided for @pageAdminProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil admin'**
  String get pageAdminProfile;

  /// No description provided for @pageSettings.
  ///
  /// In fr, this message translates to:
  /// **'Parametres'**
  String get pageSettings;

  /// No description provided for @fabProduct.
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get fabProduct;

  /// No description provided for @fabSale.
  ///
  /// In fr, this message translates to:
  /// **'Vente'**
  String get fabSale;

  /// No description provided for @fabExpense.
  ///
  /// In fr, this message translates to:
  /// **'Depense'**
  String get fabExpense;

  /// No description provided for @fabClient.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get fabClient;

  /// No description provided for @sidebarNoEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email non disponible'**
  String get sidebarNoEmail;

  /// No description provided for @sidebarDefaultAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Administrateur'**
  String get sidebarDefaultAdmin;

  /// No description provided for @sidebarTagline.
  ///
  /// In fr, this message translates to:
  /// **'Pilotage intelligent de votre boutique'**
  String get sidebarTagline;

  /// No description provided for @sidebarLogout.
  ///
  /// In fr, this message translates to:
  /// **'Deconnexion'**
  String get sidebarLogout;

  /// No description provided for @profileUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Profil admin mis a jour.'**
  String get profileUpdated;

  /// No description provided for @profileResetEmailSent.
  ///
  /// In fr, this message translates to:
  /// **'Email de reinitialisation envoye.'**
  String get profileResetEmailSent;

  /// No description provided for @profileRequiredField.
  ///
  /// In fr, this message translates to:
  /// **'{field} est obligatoire.'**
  String profileRequiredField(Object field);

  /// No description provided for @profileTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil admin'**
  String get profileTitle;

  /// No description provided for @profileSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Gere ton identite, mets a jour ton nom et securise ton compte administrateur.'**
  String get profileSubtitle;

  /// No description provided for @profileAdminAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte administrateur'**
  String get profileAdminAccount;

  /// No description provided for @profileInfoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Informations du profil'**
  String get profileInfoTitle;

  /// No description provided for @profileInfoSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Mets a jour ton prenom et ton nom pour personnaliser l\'application.'**
  String get profileInfoSubtitle;

  /// No description provided for @profileFirstName.
  ///
  /// In fr, this message translates to:
  /// **'Prenom'**
  String get profileFirstName;

  /// No description provided for @profileLastName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get profileLastName;

  /// No description provided for @profileResetPassword.
  ///
  /// In fr, this message translates to:
  /// **'Reinitialiser le mot de passe'**
  String get profileResetPassword;

  /// No description provided for @profileSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le profil'**
  String get profileSave;

  /// No description provided for @profileSaving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement...'**
  String get profileSaving;

  /// No description provided for @profileDarkMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get profileDarkMode;

  /// No description provided for @profileDarkModeDesc.
  ///
  /// In fr, this message translates to:
  /// **'Active un theme fonce pour les sessions de nuit.'**
  String get profileDarkModeDesc;

  /// No description provided for @profileLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get profileLanguage;

  /// No description provided for @profileLanguageDesc.
  ///
  /// In fr, this message translates to:
  /// **'Choisis la langue de l\'application (FR/EN).'**
  String get profileLanguageDesc;

  /// No description provided for @profileTipTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conseil'**
  String get profileTipTitle;

  /// No description provided for @profileTipBody.
  ///
  /// In fr, this message translates to:
  /// **'Les modifications du nom se synchronisent avec Firebase Auth et seront visibles dans le tableau de bord.'**
  String get profileTipBody;

  /// No description provided for @languageFr.
  ///
  /// In fr, this message translates to:
  /// **'FR'**
  String get languageFr;

  /// No description provided for @languageEn.
  ///
  /// In fr, this message translates to:
  /// **'EN'**
  String get languageEn;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
