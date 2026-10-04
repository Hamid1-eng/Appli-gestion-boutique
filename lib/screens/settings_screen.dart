import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_settings_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/clients_provider.dart';
import '../providers/expenses_provider.dart';
import '../providers/products_provider.dart';
import '../providers/sales_provider.dart';
import '../providers/suppliers_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onOpenProfile});

  final VoidCallback? onOpenProfile;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _pumpkin = Color(0xFFFF7518);
  static const Color _charcoal = Color(0xFF36454F);
  static const Color _offWhite = Color(0xFFF8F9FC);

  final TextEditingController _adminPhoneCtrl = TextEditingController();
  final TextEditingController _businessNameCtrl = TextEditingController();
  final TextEditingController _businessAddressCtrl = TextEditingController();
  final TextEditingController _businessPhoneCtrl = TextEditingController();
  final TextEditingController _logoUrlCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isRunningDataAction = false;

  String _currency = 'GNF';
  String _dateFormat = 'dd/MM/yyyy';
  String _amountFormat = '1 234 567,89';

  DateTime? _createdAt;
  String? _loadedAdminId;

  bool get _isFrench => Localizations.localeOf(context).languageCode == 'fr';
  String _t(String fr, String en) => _isFrench ? fr : en;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  @override
  void dispose() {
    _adminPhoneCtrl.dispose();
    _businessNameCtrl.dispose();
    _businessAddressCtrl.dispose();
    _businessPhoneCtrl.dispose();
    _logoUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final AuthProvider auth = context.read<AuthProvider>();
    final String? adminId = auth.currentAdminId;
    if (adminId == null || adminId.isEmpty) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final DocumentSnapshot<Map<String, dynamic>> doc = await FirebaseFirestore
          .instance
          .collection('admin_profiles')
          .doc(adminId)
          .get();
      final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};

      final String dateFormat = (data['dateFormat'] ?? '').toString().trim();
      final String amountFormat = (data['amountFormat'] ?? '')
          .toString()
          .trim();
      final String currency = (data['currency'] ?? '').toString().trim();
      final String effectiveCurrency =
          <String>['GNF', 'FCFA', 'EUR'].contains(currency) ? currency : 'GNF';
      final String effectiveDateFormat =
          <String>[
            'dd/MM/yyyy',
            'MM/dd/yyyy',
            'yyyy-MM-dd',
          ].contains(dateFormat)
          ? dateFormat
          : 'dd/MM/yyyy';
      final String effectiveAmountFormat =
          <String>['1 234 567,89', '1,234,567.89'].contains(amountFormat)
          ? amountFormat
          : '1 234 567,89';

      if (!mounted) {
        return;
      }

      setState(() {
        _loadedAdminId = adminId;
        _adminPhoneCtrl.text = (data['adminPhone'] ?? '').toString();
        _businessNameCtrl.text = (data['businessName'] ?? '').toString();
        _businessAddressCtrl.text = (data['businessAddress'] ?? '').toString();
        _businessPhoneCtrl.text = (data['businessPhone'] ?? '').toString();
        _logoUrlCtrl.text = (data['logoUrl'] ?? '').toString();
        _currency = effectiveCurrency;
        _dateFormat = effectiveDateFormat;
        _amountFormat = effectiveAmountFormat;
        _createdAt = _resolveCreatedAt(data);
        _isLoading = false;
      });

      final AppSettingsProvider appSettings = context
          .read<AppSettingsProvider>();
      await appSettings.setCurrencyCode(effectiveCurrency);
      await appSettings.setDateFormatPattern(effectiveDateFormat);
      await appSettings.setAmountFormatPattern(effectiveAmountFormat);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Impossible de charger les paramètres: $error',
              'Unable to load settings: $error',
            ),
          ),
        ),
      );
    }
  }

  DateTime? _resolveCreatedAt(Map<String, dynamic> data) {
    final dynamic raw = data['createdAt'];
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is String) {
      return DateTime.tryParse(raw);
    }
    return fb_auth.FirebaseAuth.instance.currentUser?.metadata.creationTime;
  }

  Future<void> _saveProfileAndPreferences() async {
    final AuthProvider auth = context.read<AuthProvider>();
    final AppSettingsProvider appSettings = context.read<AppSettingsProvider>();
    final String? adminId = auth.currentAdminId;
    if (adminId == null || adminId.isEmpty) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('admin_profiles')
          .doc(adminId)
          .set(<String, dynamic>{
            'adminId': adminId,
            'email':
                auth.currentAdminProfileEmail ?? auth.currentAdminEmail ?? '',
            'displayName': auth.currentAdminDisplayName,
            'adminPhone': _adminPhoneCtrl.text.trim(),
            'businessName': _businessNameCtrl.text.trim(),
            'businessAddress': _businessAddressCtrl.text.trim(),
            'businessPhone': _businessPhoneCtrl.text.trim(),
            'currency': _currency,
            'logoUrl': _logoUrlCtrl.text.trim(),
            'dateFormat': _dateFormat,
            'amountFormat': _amountFormat,
            'updatedAt': FieldValue.serverTimestamp(),
            'createdAt': _createdAt != null
                ? Timestamp.fromDate(_createdAt!)
                : FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      await appSettings.setCurrencyCode(_currency);
      await appSettings.setDateFormatPattern(_dateFormat);
      await appSettings.setAmountFormatPattern(_amountFormat);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Paramètres enregistrés avec succès.',
              'Settings saved successfully.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Erreur pendant la sauvegarde des paramètres: $error',
              'Error while saving settings: $error',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _changePassword() async {
    try {
      await context.read<AuthProvider>().sendPasswordReset();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Email de réinitialisation envoyé avec succès.',
              'Password reset email sent successfully.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Erreur lors de la réinitialisation: $error',
              'Password reset failed: $error',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await context.read<AuthProvider>().signOut();
  }

  Future<void> _exportData() async {
    setState(() {
      _isRunningDataAction = true;
    });

    try {
      final AuthProvider auth = context.read<AuthProvider>();
      final ProductsProvider products = context.read<ProductsProvider>();
      final ClientsProvider clients = context.read<ClientsProvider>();
      final SalesProvider sales = context.read<SalesProvider>();
      final ExpensesProvider expenses = context.read<ExpensesProvider>();
      final SuppliersProvider suppliers = context.read<SuppliersProvider>();

      final Map<String, dynamic> payload = <String, dynamic>{
        'adminId': auth.currentAdminId,
        'exportedAt': DateTime.now().toIso8601String(),
        'products': products.products.map((e) => e.toJson()).toList(),
        'clients': clients.clients.map((e) => e.toJson()).toList(),
        'sales': sales.sales.map((e) => e.toJson()).toList(),
        'expenses': expenses.expenses.map((e) => e.toJson()).toList(),
        'suppliers': suppliers.suppliers.map((e) => e.toJson()).toList(),
      };

      final JsonEncoder encoder = const JsonEncoder.withIndent('  ');
      final String jsonText = encoder.convert(payload);
      final XFile file = XFile.fromData(
        Uint8List.fromList(utf8.encode(jsonText)),
        mimeType: 'application/json',
        name:
            'appligestion_export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.json',
      );

      await Share.shareXFiles(
        <XFile>[file],
        subject: _t('Export données AppliGestion', 'AppliGestion data export'),
        text: _t('Export des données admin.', 'Admin data export.'),
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Export lancé avec succès.', 'Export started successfully.'),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Export impossible: $error', 'Export failed: $error'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRunningDataAction = false;
        });
      }
    }
  }

  Future<void> _resetDataWithConfirmation() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AuthProvider auth = context.read<AuthProvider>();
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(_t('Réinitialiser les données', 'Reset data')),
              content: Text(
                _t(
                  'Cette action supprimera vos données (produits, clients, ventes, dépenses, fournisseurs). Cette action est irréversible. Continuer ?',
                  'This action will delete your data (products, clients, sales, expenses, suppliers). This action cannot be undone. Continue?',
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(_t('Annuler', 'Cancel')),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(_t('Oui, réinitialiser', 'Yes, reset')),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) {
      return;
    }

    final String? adminId = auth.currentAdminId;
    if (adminId == null || adminId.isEmpty) {
      return;
    }

    setState(() {
      _isRunningDataAction = true;
    });

    try {
      const List<String> collections = <String>[
        'sales',
        'products',
        'clients',
        'expenses',
        'suppliers',
      ];

      for (final String name in collections) {
        await _deleteCollectionForAdmin(name, adminId);
      }

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'Données réinitialisées avec succès.',
              'Data reset completed successfully.',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Réinitialisation échouée: $error', 'Reset failed: $error'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRunningDataAction = false;
        });
      }
    }
  }

  Future<void> _deleteCollectionForAdmin(
    String collection,
    String adminId,
  ) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    while (true) {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
          .collection(collection)
          .where('adminId', isEqualTo: adminId)
          .limit(250)
          .get();

      if (snapshot.docs.isEmpty) {
        return;
      }

      final WriteBatch batch = firestore.batch();
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    }
  }

  String _formatCreatedAt() {
    if (_createdAt == null) {
      return _t('Non disponible', 'Not available');
    }
    return context.read<AppSettingsProvider>().formatDateTime(_createdAt!);
  }

  String _fallbackPhoneLabel() {
    final String text = _adminPhoneCtrl.text.trim();
    if (text.isNotEmpty) {
      return text;
    }
    return _t('Non renseigné', 'Not set');
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = context.watch<AuthProvider>();
    final AppSettingsProvider appSettings = context
        .watch<AppSettingsProvider>();
    final AppLocalizations? l10n = AppLocalizations.of(context);

    final String adminName = auth.currentAdminDisplayName;
    final String adminEmail =
        auth.currentAdminProfileEmail ??
        auth.currentAdminEmail ??
        _t('Non disponible', 'Not available');

    if (_loadedAdminId != auth.currentAdminId && !_isLoading) {
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSettings();
      });
    }

    final Widget content = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool twoColumns = constraints.maxWidth >= 1120;
              final double cardWidth = twoColumns
                  ? (constraints.maxWidth - 20) / 2
                  : constraints.maxWidth;

              final List<Widget> cards = <Widget>[
                _buildAccountSection(adminName, adminEmail),
                _buildBusinessSection(),
                _buildPreferencesSection(appSettings),
                _buildDataSection(),
                _buildSecuritySection(),
                _buildAboutSection(),
              ];

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n?.pageSettings ?? _t('Paramètres', 'Settings'),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: _charcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _t(
                        'Configuration du compte, du commerce et de la sécurité pour votre espace admin.',
                        'Configure account, business and security for your admin workspace.',
                      ),
                      style: TextStyle(
                        color: Color(0xFF5B6973),
                        height: 1.5,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      children: cards
                          .map(
                            (Widget card) =>
                                SizedBox(width: cardWidth, child: card),
                          )
                          .toList(),
                    ),
                  ],
                ),
              );
            },
          );

    return Container(color: _offWhite, child: content);
  }

  Widget _buildAccountSection(String adminName, String adminEmail) {
    return _card(
      icon: Icons.admin_panel_settings_rounded,
      title: _t('Compte admin', 'Admin account'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _infoLine(_t('Nom', 'Name'), adminName),
          _infoLine('Email', adminEmail),
          _infoLine(_t('Téléphone', 'Phone'), _fallbackPhoneLabel()),
          _infoLine(_t('Créé le', 'Created at'), _formatCreatedAt()),
          const SizedBox(height: 14),
          TextField(
            controller: _adminPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(
              _t('Téléphone admin (optionnel)', 'Admin phone (optional)'),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: widget.onOpenProfile,
                icon: const Icon(Icons.person_rounded),
                label: Text(_t('Modifier le profil', 'Edit profile')),
              ),
              OutlinedButton.icon(
                onPressed: _changePassword,
                icon: const Icon(Icons.password_rounded),
                label: Text(_t('Changer le mot de passe', 'Change password')),
              ),
              FilledButton.icon(
                onPressed: _signOut,
                style: FilledButton.styleFrom(backgroundColor: _pumpkin),
                icon: const Icon(Icons.logout_rounded),
                label: Text(_t('Se déconnecter', 'Sign out')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessSection() {
    return _card(
      icon: Icons.storefront_rounded,
      title: _t('Informations du commerce', 'Business information'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _businessNameCtrl,
            decoration: _inputDecoration(
              _t('Nom du commerce', 'Business name'),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _businessAddressCtrl,
            decoration: _inputDecoration(_t('Adresse', 'Address')),
            minLines: 2,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _businessPhoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: _inputDecoration(
              _t('Téléphone du commerce', 'Business phone'),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _currency,
            decoration: _inputDecoration(_t('Devise', 'Currency')),
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(value: 'GNF', child: Text('GNF')),
              DropdownMenuItem<String>(value: 'FCFA', child: Text('FCFA')),
              DropdownMenuItem<String>(value: 'EUR', child: Text('€')),
            ],
            onChanged: (String? value) {
              if (value == null) {
                return;
              }
              setState(() {
                _currency = value;
              });
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _logoUrlCtrl,
            decoration: _inputDecoration(
              _t('Logo (URL optionnelle)', 'Logo (optional URL)'),
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveProfileAndPreferences,
              style: FilledButton.styleFrom(backgroundColor: _pumpkin),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_rounded),
              label: Text(
                _isSaving
                    ? _t('Enregistrement...', 'Saving...')
                    : _t('Enregistrer', 'Save'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSection(AppSettingsProvider appSettings) {
    return _card(
      icon: Icons.palette_outlined,
      title: _t('Préférences & Apparence', 'Preferences & Appearance'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SwitchListTile.adaptive(
            value: appSettings.isDarkMode,
            contentPadding: EdgeInsets.zero,
            title: Text(_t('Mode sombre', 'Dark mode')),
            subtitle: Text(
              _t(
                'Basculer entre thème clair et sombre.',
                'Toggle between light and dark theme.',
              ),
            ),
            onChanged: (bool value) {
              appSettings.setDarkMode(value);
            },
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _dateFormat,
            decoration: _inputDecoration(_t('Format de date', 'Date format')),
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: 'dd/MM/yyyy',
                child: Text('dd/MM/yyyy'),
              ),
              DropdownMenuItem<String>(
                value: 'MM/dd/yyyy',
                child: Text('MM/dd/yyyy'),
              ),
              DropdownMenuItem<String>(
                value: 'yyyy-MM-dd',
                child: Text('yyyy-MM-dd'),
              ),
            ],
            onChanged: (String? value) {
              if (value == null) {
                return;
              }
              setState(() {
                _dateFormat = value;
              });
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _amountFormat,
            decoration: _inputDecoration(
              _t('Format des montants', 'Amount format'),
            ),
            items: const <DropdownMenuItem<String>>[
              DropdownMenuItem<String>(
                value: '1 234 567,89',
                child: Text('1 234 567,89'),
              ),
              DropdownMenuItem<String>(
                value: '1,234,567.89',
                child: Text('1,234,567.89'),
              ),
            ],
            onChanged: (String? value) {
              if (value == null) {
                return;
              }
              setState(() {
                _amountFormat = value;
              });
            },
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF2E8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD6B7)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.language_rounded, size: 18, color: _pumpkin),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _t(
                      'Langue: structure prête pour extension future.',
                      'Language: structure ready for future extension.',
                    ),
                    style: const TextStyle(
                      color: _charcoal,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveProfileAndPreferences,
              style: FilledButton.styleFrom(backgroundColor: _pumpkin),
              icon: const Icon(Icons.check_circle_outline_rounded),
              label: Text(_t('Appliquer', 'Apply')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection() {
    return _card(
      icon: Icons.inventory_2_outlined,
      title: _t('Gestion des données', 'Data management'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _t(
              'Exportez vos données ou réinitialisez votre espace admin avec confirmation.',
              'Export your data or reset your admin workspace with confirmation.',
            ),
            style: TextStyle(color: Color(0xFF5E6A73), height: 1.45),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _isRunningDataAction ? null : _exportData,
                style: FilledButton.styleFrom(backgroundColor: _pumpkin),
                icon: const Icon(Icons.ios_share_rounded),
                label: Text(_t('Exporter les données', 'Export data')),
              ),
              OutlinedButton.icon(
                onPressed: _isRunningDataAction
                    ? null
                    : _resetDataWithConfirmation,
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                icon: const Icon(Icons.delete_forever_rounded),
                label: Text(_t('Réinitialiser les données', 'Reset data')),
              ),
            ],
          ),
          if (_isRunningDataAction) ...<Widget>[
            const SizedBox(height: 12),
            const LinearProgressIndicator(minHeight: 3),
          ],
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return _card(
      icon: Icons.lock_outline_rounded,
      title: _t('Sécurité', 'Security'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _t(
              'Renforcez la sécurité de votre compte administrateur.',
              'Strengthen your administrator account security.',
            ),
            style: TextStyle(color: Color(0xFF5E6A73), height: 1.45),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _changePassword,
                style: FilledButton.styleFrom(backgroundColor: _pumpkin),
                icon: const Icon(Icons.password_rounded),
                label: Text(_t('Changer le mot de passe', 'Change password')),
              ),
              OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded),
                label: Text(_t('Se déconnecter', 'Sign out')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return _card(
      icon: Icons.info_outline_rounded,
      title: _t('À propos', 'About'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _t('Application: AppliGestion', 'Application: AppliGestion'),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: _charcoal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _t('Version: 1.0.0+1', 'Version: 1.0.0+1'),
            style: const TextStyle(color: Color(0xFF5E6A73)),
          ),
          const SizedBox(height: 6),
          Text(
            _t(
              'Support: support@appligestion.gn',
              'Support: support@appligestion.gn',
            ),
            style: const TextStyle(color: Color(0xFF5E6A73)),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2E8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _pumpkin, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: _charcoal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF66727D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: _charcoal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF697783)),
      filled: true,
      fillColor: const Color(0xFFFCFDFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5EAF0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5EAF0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _pumpkin, width: 1.8),
      ),
    );
  }
}
