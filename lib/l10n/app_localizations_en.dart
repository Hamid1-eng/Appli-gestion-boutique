// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Store Management GN';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navProducts => 'Products';

  @override
  String get navSales => 'Sales';

  @override
  String get navExpenses => 'Expenses';

  @override
  String get navClients => 'Clients';

  @override
  String get navInvoices => 'Invoices';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get pageDashboard => 'Dashboard';

  @override
  String get pageProducts => 'Products';

  @override
  String get pageSales => 'Sales';

  @override
  String get pageExpenses => 'Expenses';

  @override
  String get pageClients => 'Clients';

  @override
  String get pageInvoices => 'Invoices';

  @override
  String get pageAdminProfile => 'Admin profile';

  @override
  String get pageSettings => 'Settings';

  @override
  String get fabProduct => 'Product';

  @override
  String get fabSale => 'Sale';

  @override
  String get fabExpense => 'Expense';

  @override
  String get fabClient => 'Client';

  @override
  String get sidebarNoEmail => 'Email unavailable';

  @override
  String get sidebarDefaultAdmin => 'Administrator';

  @override
  String get sidebarTagline => 'Smart management for your store';

  @override
  String get sidebarLogout => 'Sign out';

  @override
  String get profileUpdated => 'Admin profile updated.';

  @override
  String get profileResetEmailSent => 'Password reset email sent.';

  @override
  String profileRequiredField(Object field) {
    return '$field is required.';
  }

  @override
  String get profileTitle => 'Admin profile';

  @override
  String get profileSubtitle =>
      'Manage your identity, update your name, and secure your admin account.';

  @override
  String get profileAdminAccount => 'Administrator account';

  @override
  String get profileInfoTitle => 'Profile information';

  @override
  String get profileInfoSubtitle =>
      'Update your first and last name to personalize the app.';

  @override
  String get profileFirstName => 'First name';

  @override
  String get profileLastName => 'Last name';

  @override
  String get profileResetPassword => 'Reset password';

  @override
  String get profileSave => 'Save profile';

  @override
  String get profileSaving => 'Saving...';

  @override
  String get profileDarkMode => 'Dark mode';

  @override
  String get profileDarkModeDesc => 'Enable a dark theme for night sessions.';

  @override
  String get profileLanguage => 'Language';

  @override
  String get profileLanguageDesc => 'Choose the app language (FR/EN).';

  @override
  String get profileTipTitle => 'Tip';

  @override
  String get profileTipBody =>
      'Name changes are synced to Firebase Auth and will appear in the dashboard.';

  @override
  String get languageFr => 'FR';

  @override
  String get languageEn => 'EN';
}
