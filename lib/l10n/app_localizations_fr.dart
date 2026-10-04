// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Gestion Boutique GN';

  @override
  String get navDashboard => 'Tableau';

  @override
  String get navProducts => 'Produits';

  @override
  String get navSales => 'Ventes';

  @override
  String get navExpenses => 'Depenses';

  @override
  String get navClients => 'Clients';

  @override
  String get navInvoices => 'Factures';

  @override
  String get navProfile => 'Profil';

  @override
  String get navSettings => 'Parametres';

  @override
  String get pageDashboard => 'Tableau de bord';

  @override
  String get pageProducts => 'Produits';

  @override
  String get pageSales => 'Ventes';

  @override
  String get pageExpenses => 'Depenses';

  @override
  String get pageClients => 'Clients';

  @override
  String get pageInvoices => 'Factures';

  @override
  String get pageAdminProfile => 'Profil admin';

  @override
  String get pageSettings => 'Parametres';

  @override
  String get fabProduct => 'Produit';

  @override
  String get fabSale => 'Vente';

  @override
  String get fabExpense => 'Depense';

  @override
  String get fabClient => 'Client';

  @override
  String get sidebarNoEmail => 'Email non disponible';

  @override
  String get sidebarDefaultAdmin => 'Administrateur';

  @override
  String get sidebarTagline => 'Pilotage intelligent de votre boutique';

  @override
  String get sidebarLogout => 'Deconnexion';

  @override
  String get profileUpdated => 'Profil admin mis a jour.';

  @override
  String get profileResetEmailSent => 'Email de reinitialisation envoye.';

  @override
  String profileRequiredField(Object field) {
    return '$field est obligatoire.';
  }

  @override
  String get profileTitle => 'Profil admin';

  @override
  String get profileSubtitle =>
      'Gere ton identite, mets a jour ton nom et securise ton compte administrateur.';

  @override
  String get profileAdminAccount => 'Compte administrateur';

  @override
  String get profileInfoTitle => 'Informations du profil';

  @override
  String get profileInfoSubtitle =>
      'Mets a jour ton prenom et ton nom pour personnaliser l\'application.';

  @override
  String get profileFirstName => 'Prenom';

  @override
  String get profileLastName => 'Nom';

  @override
  String get profileResetPassword => 'Reinitialiser le mot de passe';

  @override
  String get profileSave => 'Enregistrer le profil';

  @override
  String get profileSaving => 'Enregistrement...';

  @override
  String get profileDarkMode => 'Mode sombre';

  @override
  String get profileDarkModeDesc =>
      'Active un theme fonce pour les sessions de nuit.';

  @override
  String get profileLanguage => 'Langue';

  @override
  String get profileLanguageDesc =>
      'Choisis la langue de l\'application (FR/EN).';

  @override
  String get profileTipTitle => 'Conseil';

  @override
  String get profileTipBody =>
      'Les modifications du nom se synchronisent avec Firebase Auth et seront visibles dans le tableau de bord.';

  @override
  String get languageFr => 'FR';

  @override
  String get languageEn => 'EN';
}
