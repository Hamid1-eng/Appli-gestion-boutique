import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _firstNameCtrl = TextEditingController();
  final TextEditingController _lastNameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isCreateMode = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String firstName = _firstNameCtrl.text.trim();
    final String lastName = _lastNameCtrl.text.trim();
    final String email = _emailCtrl.text.trim();
    final String password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Email et mot de passe sont obligatoires.');
      return;
    }

    final bool emailLooksValid = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(email);
    if (!emailLooksValid) {
      _showMessage('Veuillez saisir une adresse email valide.');
      return;
    }

    if (_isCreateMode && password.length < 6) {
      _showMessage('Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }

    if (_isCreateMode && (firstName.isEmpty || lastName.isEmpty)) {
      _showMessage('Prénom et nom sont obligatoires pour créer un admin.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final AuthProvider auth = context.read<AuthProvider>();
      if (_isCreateMode) {
        await auth.createAdmin(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
        );
      } else {
        await auth.signInAdmin(email: email, password: password);
      }
    } on FirebaseAuthException catch (error) {
      _showMessage(_authErrorMessage(error));
    } catch (_) {
      _showMessage('Une erreur est survenue.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _authErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'Cet email est déjà utilisé. Connectez-vous ou utilisez un autre email.';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'weak-password':
        return 'Mot de passe trop faible. Utilisez au moins 6 caractères.';
      case 'operation-not-allowed':
        return 'La création de compte par email/mot de passe est désactivée dans Firebase.';
      case 'network-request-failed':
        return 'Connexion réseau indisponible. Vérifiez Internet puis réessayez.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez dans quelques minutes.';
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Identifiants invalides.';
      default:
        return error.message ?? 'Erreur d\'authentification (${error.code}).';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _forgotPassword() async {
    final String email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      _showMessage('Entre ton email pour réinitialiser le mot de passe.');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _showMessage('Email de réinitialisation envoyé.');
    } on FirebaseAuthException catch (error) {
      _showMessage(error.message ?? 'Impossible d\'envoyer l\'email.');
    } catch (_) {
      _showMessage('Une erreur est survenue.');
    }
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    bool obscure = false,
    TextInputType? keyboardType,
    Widget? prefixIcon,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF4E3A31),
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE5E8EC),
            borderRadius: BorderRadius.circular(28),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            keyboardType: keyboardType,
            textCapitalization: textCapitalization,
            style: const TextStyle(
              color: Color(0xFF4D5C6A),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 18,
              ),
              prefixIcon: prefixIcon,
              suffixIcon: suffixIcon,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE5E8EC),
        borderRadius: BorderRadius.circular(28),
      ),
      child: TextField(
        controller: _passwordCtrl,
        obscureText: _obscurePassword,
        style: const TextStyle(
          color: Color(0xFF4D5C6A),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 18,
          ),
          prefixIcon: const Icon(Icons.lock, color: Color(0xFF687581)),
          suffixIcon: IconButton(
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: const Color(0xFF687581),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthFormCard({required bool desktop}) {
    final String title = _isCreateMode
        ? 'Créer un compte admin'
        : 'Bon retour parmi nous';
    final String subtitle = _isCreateMode
        ? 'Renseignez les informations administrateur pour démarrer.'
        : 'Veuillez entrer vos identifiants pour accéder au tableau de bord.';

    return Container(
      padding: EdgeInsets.fromLTRB(
        desktop ? 32 : 26,
        desktop ? 32 : 26,
        desktop ? 32 : 26,
        desktop ? 34 : 30,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F0EC),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE9E2DB)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF2B3441).withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF1B2430),
              fontSize: desktop ? 40 : 30,
              height: 1.02,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              color: const Color(0xFF64748B),
              fontSize: desktop ? 14 : 15,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          if (_isCreateMode) ...<Widget>[
            _buildInputField(
              label: 'PRÉNOM',
              controller: _firstNameCtrl,
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(
                Icons.person_rounded,
                color: Color(0xFF687581),
              ),
            ),
            const SizedBox(height: 14),
            _buildInputField(
              label: 'NOM',
              controller: _lastNameCtrl,
              textCapitalization: TextCapitalization.words,
              prefixIcon: const Icon(
                Icons.badge_rounded,
                color: Color(0xFF687581),
              ),
            ),
            const SizedBox(height: 14),
          ],
          _buildInputField(
            label: 'NOM D\'UTILISATEUR',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.person, color: Color(0xFF687581)),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              const Text(
                'MOT DE PASSE',
                style: TextStyle(
                  color: Color(0xFF4E3A31),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              if (!_isCreateMode)
                TextButton(
                  onPressed: _isLoading ? null : _forgotPassword,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF7315),
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Oublié ?',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          _buildPasswordField(),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Checkbox(
                value: _rememberMe,
                onChanged: _isLoading
                    ? null
                    : (bool? value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                side: const BorderSide(color: Color(0xFFCCD4DB)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                fillColor: WidgetStateProperty.resolveWith<Color>((
                  Set<WidgetState> states,
                ) {
                  if (states.contains(WidgetState.selected)) {
                    return const Color(0xFFFF7315);
                  }
                  return const Color(0xFFE5E8EC);
                }),
                checkColor: Colors.white,
              ),
              const SizedBox(width: 4),
              const Text(
                'Rester connecté',
                style: TextStyle(
                  color: Color(0xFF536575),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF7315),
                foregroundColor: Colors.white,
                elevation: 10,
                shadowColor: const Color(0xFFFF7315).withValues(alpha: 0.28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                textStyle: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(
                _isLoading
                    ? 'Chargement...'
                    : (_isCreateMode
                          ? 'Créer le compte admin'
                          : 'Se connecter'),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const Divider(color: Color(0xFFDEE3E8), height: 1),
          const SizedBox(height: 18),
          Text(
            _isCreateMode
                ? 'Vous avez déjà un compte ?'
                : 'Nouveau sur la plateforme ?',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF536575),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isCreateMode = !_isCreateMode;
                        if (!_isCreateMode) {
                          _firstNameCtrl.clear();
                          _lastNameCtrl.clear();
                        }
                      });
                    },
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF334155),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                backgroundColor: const Color(0xFFE2E8F0),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                _isCreateMode
                    ? 'J\'ai déjà un compte admin'
                    : 'Créer un compte admin',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[Color(0xFFF2F0EF), Color(0xFFEAD5C7)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compactHeight = constraints.maxHeight < 860;
              final bool compactWidth = constraints.maxWidth < 1360;
              final bool showMetrics = !compactHeight;
              final double heroTitleSize = compactHeight
                  ? 48
                  : (compactWidth ? 56 : 62);
              final double subtitleSize = compactHeight
                  ? 22
                  : (compactWidth ? 26 : 30);
              final double leftTopGap = compactHeight ? 18 : 34;
              final double heroBottomGap = compactHeight ? 18 : 24;
              final double blockGap = compactHeight ? 22 : 34;
              final double rightPanelWidth = compactWidth ? 520 : 560;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 48,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(0, 20, 24, 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFF7315),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.insert_chart_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'AppliGestion',
                                    style: TextStyle(
                                      color: Color(0xFF111827),
                                      fontSize: 40,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: leftTopGap),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: const Color(0xFF111827),
                                    fontSize: heroTitleSize,
                                    height: 1.08,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  children: const <TextSpan>[
                                    TextSpan(
                                      text: 'Pilotez votre entreprise\navec ',
                                    ),
                                    TextSpan(
                                      text: 'clarté',
                                      style: TextStyle(
                                        color: Color(0xFFFF7315),
                                      ),
                                    ),
                                    TextSpan(text: ' et élégance.'),
                                  ],
                                ),
                              ),
                              SizedBox(height: heroBottomGap),
                              SizedBox(
                                width: compactWidth ? 620 : 720,
                                child: Text(
                                  'L\'interface curatoriale conçue pour transformer la gestion complexe en une expérience fluide et prévisible.',
                                  style: TextStyle(
                                    color: const Color(0xFF475569),
                                    fontSize: subtitleSize,
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (showMetrics) ...<Widget>[
                                SizedBox(height: blockGap),
                                Wrap(
                                  spacing: 14,
                                  runSpacing: 14,
                                  children: <Widget>[
                                    _buildDesktopMetric(
                                      title: 'CHIFFRE D\'AFFAIRES',
                                      value: '142.5k GNF',
                                      hint: '↗ +12%',
                                    ),
                                    _buildDesktopMetric(
                                      title: 'PROJETS ACTIFS',
                                      value: '24',
                                      hint: '● ● ●',
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      SizedBox(
                        width: rightPanelWidth,
                        child: Align(
                          alignment: Alignment.topRight,
                          child: _buildAuthFormCard(desktop: true),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopMetric({
    required String title,
    required String value,
    required String hint,
  }) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            style: const TextStyle(
              color: Color(0xFFB42318),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[Color(0xFFFF7A1A), Color(0xFF5A6B78)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: _buildAuthFormCard(desktop: false),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  children: <Widget>[
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.verified_user_rounded,
                          size: 18,
                          color: Color(0xFFE6DDD7),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'SÉCURISÉ SSL',
                          style: TextStyle(
                            color: Color(0xFFE6DDD7),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(width: 26),
                        Icon(
                          Icons.cloud_done_rounded,
                          size: 18,
                          color: Color(0xFFE6DDD7),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'CLOUD GUINÉE',
                          style: TextStyle(
                            color: Color(0xFFE6DDD7),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D5450).withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.language_rounded,
                            color: Color(0xFFE6DDD7),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Français (Guinée)',
                            style: TextStyle(
                              color: Color(0xFFE6DDD7),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Color(0xFFE6DDD7),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.sizeOf(context).width >= 1024;
    if (isDesktop) {
      return _buildDesktopLayout();
    }
    return _buildMobileLayout();
  }
}
