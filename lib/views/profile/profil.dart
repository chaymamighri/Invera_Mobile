import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:invera_mobile/models/commande.dart';
import 'package:invera_mobile/models/utilisateur.dart';
import 'package:invera_mobile/config/routes.dart';
import 'package:invera_mobile/services/authentification.dart';
import 'package:invera_mobile/services/commandes.dart';

// Valeurs globales partagees utilisees par l'interface.
const Color _primary = Color(0xFF2D47C8);
const Color _primaryDark = Color(0xFF2037A7);
const Color _background = Color(0xFFF4F7FC);
const Color _surface = Colors.white;
const Color _textPrimary = Color(0xFF1F2A44);
const Color _textSecondary = Color(0xFF607089);
const Color _border = Color(0xFFE6EAF2);
const Color _success = Color(0xFF16A34A);
const Color _danger = Color(0xFFDC2626);

/// Widget qui affiche l'ecran de profil.
class ProfileScreen extends StatefulWidget {
  // Configuration, dependances et etat local de l'interface.
  final User user;

  const ProfileScreen({super.key, required this.user});

  // Cycle de vie du widget.

  /// Cree l'objet d'etat mutable de ce widget.
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

/// Objet d'etat qui stocke les donnees temporaires de l'interface pour l'ecran de profil.
class _ProfileScreenState extends State<ProfileScreen> {
  // Configuration, dependances et etat local de l'interface.
  final AuthService _authService = AuthService();
  final CommandeService _commandeService = CommandeService();

  late User _user;
  bool _loading = true;
  bool _refreshing = false;
  String? _warning;
  DateTime? _lastSync;

  List<CommandeModel> _commandes = <CommandeModel>[];

  // Cycle de vie du widget.

  /// S'execute une seule fois quand le widget est insere dans l'arbre des widgets.
  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _reload(showLoader: true);
  }

  // Valeurs calculees et methodes utilitaires.

  /// Execute la requete de maniere sure et utilise une valeur de secours en cas d'echec.
  Future<T> _safe<T>(Future<T> request, T fallback) async {
    try {
      return await request;
    } catch (_) {
      return fallback;
    }
  }

  /// Recharge les donnees actuelles.
  Future<void> _reload({bool showLoader = false}) async {
    if (showLoader) {
      setState(() {
        _loading = true;
        _warning = null;
      });
    } else {
      setState(() => _refreshing = true);
    }

    try {
      await _authService.ready();
      final refreshed = await _authService.fetchCurrentUser();
      if ((refreshed || _authService.currentUser != null) &&
          _authService.currentUser != null) {
        _user = _authService.currentUser!;
      }

      if (_user.role == UserRole.COMMERCIAL ||
          _user.role == UserRole.RESPONSABLE_VENTE) {
        final commandes = await _safe(
          _commandeService.getCommandes(),
          <CommandeModel>[],
        );
        _commandes = commandes;
      } else {
        _commandes = <CommandeModel>[];
      }

      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _warning = null;
        _lastSync = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _refreshing = false;
        _warning = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Retourne le libelle affiche pour le role actuel de l'utilisateur.
  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.ADMIN:
        return 'Administrateur';
      case UserRole.RESPONSABLE_ACHAT:
        return 'Responsable achat';
      case UserRole.RESPONSABLE_VENTE:
        return 'Responsable vente';
      case UserRole.COMMERCIAL:
        return 'Commercial';
    }
  }

  /// Construit les initiales affichees dans l'avatar.
  String _initials() {
    final full = '${_user.prenom} ${_user.nom}'.trim();
    if (full.isEmpty) return 'US';
    final parts = full.split(' ').where((e) => e.trim().isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  /// Retourne les elements recents.
  List<CommandeModel> get _recent {
    final list = List<CommandeModel>.from(_commandes)
      ..sort((a, b) => b.idCommandeClient.compareTo(a.idCommandeClient));
    return list.take(5).toList();
  }

  /// Methode utilitaire pour la couleur du statut.
  Color _statusColor(String status) {
    final s = status.trim().toUpperCase();
    if (s == 'EN_ATTENTE') return const Color(0xFFD97706);
    if (s == 'VALIDEE' || s == 'CONFIRMEE') return _success;
    if (s == 'ANNULEE' || s == 'REJETEE') return _danger;
    return _primary;
  }

  /// Formate amount pour l'affichage.
  String _money(double v) => '${v.toStringAsFixed(2)} DT';

  /// Formate date pour l'affichage.
  String _date(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  // Actions utilisateur et traitements asynchrones.

  /// Copie l'e-mail.
  Future<void> _copyEmail() async {
    await Clipboard.setData(ClipboardData(text: _user.email));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email copie'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Valeurs calculees et methodes utilitaires.

  /// Methode utilitaire pour le champ securise du mot de passe.
  Widget _securePasswordInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
    required VoidCallback onChanged,
    TextInputAction textInputAction = TextInputAction.next,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: (_) => onChanged(),
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: _background,
        prefixIcon: Icon(icon, color: _primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _danger, width: 2),
        ),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          ),
        ),
      ),
      validator: validator,
    );
  }

  /// Methode utilitaire pour le score du mot de passe.
  int _passwordScore(String value) {
    var score = 0;
    if (value.length >= 8) score += 1;
    if (RegExp(r'[A-Z]').hasMatch(value)) score += 1;
    if (RegExp(r'[0-9]').hasMatch(value)) score += 1;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\\/+=;]').hasMatch(value)) {
      score += 1;
    }
    return score;
  }

  /// Methode utilitaire pour la couleur de la force du mot de passe.
  Color _passwordStrengthColor(int score) {
    if (score <= 1) return _danger;
    if (score == 2) return const Color(0xFFD97706);
    if (score == 3) return const Color(0xFF0284C7);
    return _success;
  }

  /// Methode utilitaire pour le libelle de la force du mot de passe.
  String _passwordStrengthLabel(int score) {
    if (score <= 1) return 'Faible';
    if (score == 2) return 'Moyen';
    if (score == 3) return 'Fort';
    return 'Tres fort';
  }

  /// Methode utilitaire pour la regle du mot de passe.
  Widget _passwordRule({required bool valid, required String label}) {
    final color = valid ? _success : _textSecondary;
    return Row(
      children: [
        Icon(
          valid ? Icons.check_circle_outline : Icons.radio_button_unchecked,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: valid ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Methode utilitaire pour le champ des parametres du profil.
  Widget _profileSettingInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required VoidCallback onChanged,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: _background,
        prefixIcon: Icon(icon, color: _primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _danger, width: 2),
        ),
      ),
      validator: validator,
    );
  }

  // Actions utilisateur et traitements asynchrones.

  /// Affiche le dialogue des parametres du profil.
  Future<void> _showProfileSettingsDialog() async {
    final formKey = GlobalKey<FormState>();
    final nomCtrl = TextEditingController(text: _user.nom);
    final prenomCtrl = TextEditingController(text: _user.prenom);
    final emailCtrl = TextEditingController(text: _user.email);

    var submitting = false;
    String? serverError;
    var successMessage = 'Profil mis a jour avec succes';
    var requireReauth = false;

    final didSave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void onInputsChanged() {
              if (serverError != null) {
                setDialogState(() => serverError = null);
              }
            }

            Future<void> submit() async {
              FocusScope.of(dialogContext).unfocus();
              if (!(formKey.currentState?.validate() ?? false) || submitting) {
                return;
              }

              setDialogState(() {
                submitting = true;
                serverError = null;
              });

              final result = await _authService.updateProfile(
                nom: nomCtrl.text,
                prenom: prenomCtrl.text,
                email: emailCtrl.text,
              );

              if (!mounted || !dialogContext.mounted) return;

              if (result.success) {
                successMessage = result.message;
                final newEmail = emailCtrl.text.trim().toLowerCase();
                final currentEmail = _user.email.trim().toLowerCase();
                requireReauth = newEmail != currentEmail;
                Navigator.of(dialogContext, rootNavigator: true).pop(true);
                return;
              }

              setDialogState(() {
                submitting = false;
                serverError = result.message;
              });
            }

            final compact = MediaQuery.of(context).size.width < 760;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: compact ? 14 : 28,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primary, _primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.manage_accounts_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Parametres du profil',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Mettez a jour vos informations personnelles.',
                                  style: TextStyle(
                                    color: Color(0xFFE7EEFF),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: submitting
                                ? null
                                : () => Navigator.of(
                                    dialogContext,
                                    rootNavigator: true,
                                  ).pop(false),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            children: [
                              if (compact) ...[
                                _profileSettingInput(
                                  controller: prenomCtrl,
                                  label: 'Prenom',
                                  hint: 'Votre prenom',
                                  icon: Icons.person_outline,
                                  onChanged: onInputsChanged,
                                  validator: (v) {
                                    final value = (v ?? '').trim();
                                    if (value.isEmpty) return 'Prenom requis';
                                    if (value.length < 2) {
                                      return 'Minimum 2 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _profileSettingInput(
                                  controller: nomCtrl,
                                  label: 'Nom',
                                  hint: 'Votre nom',
                                  icon: Icons.person_outline,
                                  onChanged: onInputsChanged,
                                  validator: (v) {
                                    final value = (v ?? '').trim();
                                    if (value.isEmpty) return 'Nom requis';
                                    if (value.length < 2) {
                                      return 'Minimum 2 caracteres';
                                    }
                                    return null;
                                  },
                                ),
                              ] else ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: _profileSettingInput(
                                        controller: prenomCtrl,
                                        label: 'Prenom',
                                        hint: 'Votre prenom',
                                        icon: Icons.person_outline,
                                        onChanged: onInputsChanged,
                                        validator: (v) {
                                          final value = (v ?? '').trim();
                                          if (value.isEmpty) {
                                            return 'Prenom requis';
                                          }
                                          if (value.length < 2) {
                                            return 'Minimum 2 caracteres';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _profileSettingInput(
                                        controller: nomCtrl,
                                        label: 'Nom',
                                        hint: 'Votre nom',
                                        icon: Icons.person_outline,
                                        onChanged: onInputsChanged,
                                        validator: (v) {
                                          final value = (v ?? '').trim();
                                          if (value.isEmpty) {
                                            return 'Nom requis';
                                          }
                                          if (value.length < 2) {
                                            return 'Minimum 2 caracteres';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),
                              _profileSettingInput(
                                controller: emailCtrl,
                                label: 'Email',
                                hint: 'exemple@email.com',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                onChanged: onInputsChanged,
                                validator: (v) {
                                  final value = (v ?? '').trim();
                                  if (value.isEmpty) return 'Email requis';
                                  if (!RegExp(
                                    r'^[^@]+@[^@]+\.[^@]+$',
                                  ).hasMatch(value)) {
                                    return 'Email invalide';
                                  }
                                  return null;
                                },
                              ),
                              if (serverError != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _danger.withValues(alpha: 0.08),
                                    border: Border.all(
                                      color: _danger.withValues(alpha: 0.22),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    serverError!,
                                    style: const TextStyle(
                                      color: _danger,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: _border)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: submitting
                                ? null
                                : () => Navigator.of(
                                    dialogContext,
                                    rootNavigator: true,
                                  ).pop(false),
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: submitting ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: submitting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Enregistrer'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nomCtrl.dispose();
    prenomCtrl.dispose();
    emailCtrl.dispose();

    if (didSave == true && mounted) {
      if (requireReauth) {
        await _authService.logout();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
        return;
      }

      await _reload();
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: _success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Affiche le dialogue de changement de mot de passe.
  Future<void> _showChangePasswordDialog() async {
    final formKey = GlobalKey<FormState>();
    final oldCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    var oldObscure = true;
    var newObscure = true;
    var confirmObscure = true;
    var submitting = false;
    String? serverError;

    final didUpdate = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void onInputsChanged() {
              if (serverError != null) {
                setDialogState(() => serverError = null);
              } else {
                setDialogState(() {});
              }
            }

            Future<void> submit() async {
              FocusScope.of(dialogContext).unfocus();
              if (!(formKey.currentState?.validate() ?? false) || submitting) {
                return;
              }

              setDialogState(() {
                submitting = true;
                serverError = null;
              });

              final result = await _authService.changePassword(
                oldPassword: oldCtrl.text,
                newPassword: newCtrl.text,
              );

              if (!mounted || !dialogContext.mounted) return;

              if (result.success) {
                Navigator.of(dialogContext, rootNavigator: true).pop(true);
                return;
              }

              setDialogState(() {
                submitting = false;
                serverError = result.message;
              });
            }

            final pass = newCtrl.text;
            final score = _passwordScore(pass);
            final strengthColor = _passwordStrengthColor(score);
            final isCompact = MediaQuery.of(context).size.width < 780;
            final hasLength = pass.length >= 8;
            final hasUpper = RegExp(r'[A-Z]').hasMatch(pass);
            final hasNumber = RegExp(r'[0-9]').hasMatch(pass);
            final hasSpecial = RegExp(
              r'[!@#$%^&*(),.?":{}|<>_\-\[\]\\\/+=;]',
            ).hasMatch(pass);
            final matches =
                confirmCtrl.text.isNotEmpty && confirmCtrl.text == newCtrl.text;

            Widget buildFormColumn() {
              return Column(
                children: [
                  _securePasswordInput(
                    controller: oldCtrl,
                    label: 'Mot de passe actuel',
                    hint: 'Entrez votre mot de passe actuel',
                    icon: Icons.lock_outline,
                    obscure: oldObscure,
                    onToggle: () =>
                        setDialogState(() => oldObscure = !oldObscure),
                    onChanged: onInputsChanged,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Mot de passe actuel requis';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _securePasswordInput(
                    controller: newCtrl,
                    label: 'Nouveau mot de passe',
                    hint: 'Choisissez un mot de passe robuste',
                    icon: Icons.password_outlined,
                    obscure: newObscure,
                    onToggle: () =>
                        setDialogState(() => newObscure = !newObscure),
                    onChanged: onInputsChanged,
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Nouveau mot de passe requis';
                      if (value.length < 8) return 'Minimum 8 caracteres';
                      if (value == oldCtrl.text) {
                        return 'Doit etre different de l ancien';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _securePasswordInput(
                    controller: confirmCtrl,
                    label: 'Confirmation',
                    hint: 'Retapez le nouveau mot de passe',
                    icon: Icons.verified_user_outlined,
                    obscure: confirmObscure,
                    onToggle: () =>
                        setDialogState(() => confirmObscure = !confirmObscure),
                    onChanged: onInputsChanged,
                    textInputAction: TextInputAction.done,
                    validator: (v) {
                      if ((v ?? '').isEmpty) return 'Confirmation requise';
                      if (v != newCtrl.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                ],
              );
            }

            Widget buildSecurityColumn() {
              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _background,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: strengthColor,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Niveau de securite',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      minHeight: 7,
                      value: score / 4,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _passwordStrengthLabel(score),
                      style: TextStyle(
                        color: strengthColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _passwordRule(
                      valid: hasLength,
                      label: 'Au moins 8 caracteres',
                    ),
                    const SizedBox(height: 8),
                    _passwordRule(
                      valid: hasUpper,
                      label: 'Au moins une majuscule',
                    ),
                    const SizedBox(height: 8),
                    _passwordRule(
                      valid: hasNumber,
                      label: 'Au moins un chiffre',
                    ),
                    const SizedBox(height: 8),
                    _passwordRule(
                      valid: hasSpecial,
                      label: 'Au moins un caractere special',
                    ),
                    const SizedBox(height: 8),
                    _passwordRule(
                      valid: matches,
                      label: 'Confirmation identique',
                    ),
                  ],
                ),
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: isCompact ? 14 : 28,
                vertical: 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 860),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primary, _primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.lock_reset_outlined,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mise a jour mot de passe',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Renforcez la securite de votre compte avec un mot de passe solide.',
                                  style: TextStyle(
                                    color: Color(0xFFE7EEFF),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: submitting
                                ? null
                                : () => Navigator.of(
                                    dialogContext,
                                    rootNavigator: true,
                                  ).pop(false),
                            icon: const Icon(Icons.close, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: formKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: Column(
                            children: [
                              if (isCompact) ...[
                                buildFormColumn(),
                                const SizedBox(height: 14),
                                buildSecurityColumn(),
                              ] else ...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(flex: 7, child: buildFormColumn()),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      flex: 5,
                                      child: buildSecurityColumn(),
                                    ),
                                  ],
                                ),
                              ],
                              if (serverError != null) ...[
                                const SizedBox(height: 14),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: _danger.withValues(alpha: 0.08),
                                    border: Border.all(
                                      color: _danger.withValues(alpha: 0.22),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    serverError!,
                                    style: const TextStyle(
                                      color: _danger,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: _border)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: submitting
                                ? null
                                : () => Navigator.of(
                                    dialogContext,
                                    rootNavigator: true,
                                  ).pop(false),
                            child: const Text('Annuler'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: submitting ? null : submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                            ),
                            icon: submitting
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.lock_reset_outlined),
                            label: const Text('Mettre a jour'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (didUpdate == true && mounted) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    }

    oldCtrl.dispose();
    newCtrl.dispose();
    confirmCtrl.dispose();
  }

  List<Map<String, dynamic>> _capabilities() {
    switch (_user.role) {
      case UserRole.ADMIN:
        return const [
          {
            'icon': Icons.admin_panel_settings_outlined,
            'title': 'Administration globale',
          },
          {'icon': Icons.query_stats_outlined, 'title': 'Pilotage transverse'},
          {
            'icon': Icons.settings_suggest_outlined,
            'title': 'Parametrage avance',
          },
        ];
      case UserRole.RESPONSABLE_ACHAT:
        return const [
          {
            'icon': Icons.inventory_2_outlined,
            'title': 'Pilotage approvisionnement',
          },
          {
            'icon': Icons.fact_check_outlined,
            'title': 'Validation des demandes',
          },
          {'icon': Icons.handshake_outlined, 'title': 'Collaboration metier'},
        ];
      case UserRole.RESPONSABLE_VENTE:
        return [
          {
            'icon': Icons.show_chart_outlined,
            'title': 'Pilotage de la performance vente',
          },
          {
            'icon': Icons.receipt_long_outlined,
            'title': 'Suivi facturation commerciale',
          },
          {
            'icon': Icons.groups_outlined,
            'title': 'Coordination equipe commerciale',
          },
        ];
      case UserRole.COMMERCIAL:
        return const [
          {
            'icon': Icons.people_alt_outlined,
            'title': 'Gestion portefeuille clients',
          },
          {
            'icon': Icons.shopping_cart_outlined,
            'title': 'Suivi cycle commandes',
          },
          {
            'icon': Icons.insights_outlined,
            'title': 'Analyse performance commerciale',
          },
        ];
    }
  }

  // Construction de l'interface.

  /// Construit l'interface visible de ce widget.
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final isPhone = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _surface,
        foregroundColor: _textPrimary,
        elevation: 0,
        title: const Text(
          'Profil professionnel',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Parametres profil',
            onPressed: _showProfileSettingsDialog,
            icon: const Icon(Icons.manage_accounts_outlined),
          ),
          IconButton(
            tooltip: 'Modifier mot de passe',
            onPressed: _showChangePasswordDialog,
            icon: const Icon(Icons.lock_reset_outlined),
          ),
          IconButton(
            tooltip: 'Copier email',
            onPressed: _copyEmail,
            icon: const Icon(Icons.copy_outlined),
          ),
          IconButton(
            tooltip: 'Actualiser',
            onPressed: _refreshing ? null : _reload,
            icon: _refreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: ListView(
              padding: EdgeInsets.all(isPhone ? 16 : 24),
              children: [
                if (_warning != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _danger.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _danger.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'Avertissement: $_warning',
                      style: const TextStyle(color: _textPrimary),
                    ),
                  ),
                Container(
                  padding: EdgeInsets.all(isPhone ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primary, _primaryDark],
                    ),
                    borderRadius: BorderRadius.circular(isPhone ? 16 : 18),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x26000000),
                        blurRadius: isPhone ? 14 : 18,
                        offset: Offset(0, isPhone ? 6 : 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: isPhone ? 28 : 36,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          _initials(),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: isPhone ? 18 : 22,
                          ),
                        ),
                      ),
                      SizedBox(width: isPhone ? 10 : 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_user.prenom} ${_user.nom}'.trim().isEmpty
                                  ? _user.email
                                  : '${_user.prenom} ${_user.nom}'.trim(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isPhone ? 18.5 : 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: isPhone ? 2 : 4),
                            Text(
                              _user.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFFE8EDFF),
                                fontSize: isPhone ? 13 : 15,
                              ),
                            ),
                            SizedBox(height: isPhone ? 6 : 8),
                            Wrap(
                              spacing: isPhone ? 6 : 8,
                              runSpacing: isPhone ? 6 : 8,
                              children: [
                                _heroChip(
                                  Icons.work_outline,
                                  _roleLabel(_user.role),
                                  compact: isPhone,
                                ),
                                _heroChip(
                                  _user.active
                                      ? Icons.verified_user_outlined
                                      : Icons.block_outlined,
                                  _user.active
                                      ? 'Compte actif'
                                      : 'Compte inactif',
                                  color: _user.active ? _success : _danger,
                                  compact: isPhone,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final mobile = constraints.maxWidth < 960;
                    final left = Column(
                      children: [
                        _panel(
                          'Informations compte',
                          Icons.person_pin_outlined,
                          Column(
                            children: [
                              _infoRow(
                                Icons.person_outline,
                                'Prenom',
                                _user.prenom,
                              ),
                              _sep(),
                              _infoRow(Icons.person_outline, 'Nom', _user.nom),
                              _sep(),
                              _infoRow(
                                Icons.email_outlined,
                                'Email',
                                _user.email,
                              ),
                              _sep(),
                              _infoRow(
                                Icons.work_outline,
                                'Role',
                                _roleLabel(_user.role),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: _showProfileSettingsDialog,
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Modifier profil'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _panel(
                          'Securite',
                          Icons.security_outlined,
                          Column(
                            children: [
                              _securityRow(
                                'Session',
                                (_authService.token ?? '').trim().isNotEmpty
                                    ? 'Active'
                                    : 'Inactive',
                                (_authService.token ?? '').trim().isNotEmpty
                                    ? _success
                                    : _danger,
                              ),
                              const SizedBox(height: 8),
                              _securityRow(
                                'Derniere sync',
                                _lastSync == null
                                    ? 'Jamais'
                                    : _date(_lastSync!),
                                _primary,
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  onPressed: _showChangePasswordDialog,
                                  icon: const Icon(Icons.lock_reset_outlined),
                                  label: const Text('Modifier mot de passe'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                    final right = Column(
                      children: [
                        _panel(
                          'Capacites de role',
                          Icons.workspace_premium_outlined,
                          Column(
                            children: _capabilities().asMap().entries.map((
                              entry,
                            ) {
                              final item = entry.value;
                              final row = Row(
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    color: _primary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      item['title'] as String,
                                      style: const TextStyle(
                                        color: _textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                              if (entry.key == _capabilities().length - 1) {
                                return row;
                              }
                              return Column(children: [row, _sep()]);
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _panel(
                          'Activite recente',
                          Icons.timeline_outlined,
                          (_user.role != UserRole.COMMERCIAL &&
                                  _user.role != UserRole.RESPONSABLE_VENTE)
                              ? const Text(
                                  'Aucune activite disponible pour ce role',
                                  style: TextStyle(color: _textSecondary),
                                )
                              : (_recent.isEmpty
                                    ? const Text(
                                        'Aucune commande disponible',
                                        style: TextStyle(color: _textSecondary),
                                      )
                                    : Column(
                                        children: _recent.asMap().entries.map((
                                          entry,
                                        ) {
                                          final c = entry.value;
                                          final color = _statusColor(c.statut);
                                          final row = Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.receipt_long_outlined,
                                                color: color,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      c.referenceCommandeClient,
                                                      style: const TextStyle(
                                                        color: _textPrimary,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${c.client?.fullName ?? 'Client'} | ${c.dateCommandeFormatted}',
                                                      style: const TextStyle(
                                                        color: _textSecondary,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: color.withValues(
                                                        alpha: 0.12,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      c.statutDisplay,
                                                      style: TextStyle(
                                                        color: color,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Text(
                                                    _money(c.total),
                                                    style: const TextStyle(
                                                      color: _textPrimary,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          );
                                          if (entry.key == _recent.length - 1) {
                                            return row;
                                          }
                                          return Column(
                                            children: [row, _sep()],
                                          );
                                        }).toList(),
                                      )),
                        ),
                      ],
                    );
                    if (mobile) {
                      return Column(
                        children: [left, const SizedBox(height: 12), right],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: left),
                        const SizedBox(width: 12),
                        Expanded(child: right),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Valeurs calculees et methodes utilitaires.

  /// Methode utilitaire pour la pastille hero.
  Widget _heroChip(
    IconData icon,
    String text, {
    Color color = Colors.white,
    bool compact = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 13 : 14, color: Colors.white),
          SizedBox(width: compact ? 5 : 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  /// Methode utilitaire pour le panneau.
  Widget _panel(String title, IconData icon, Widget child) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// Methode utilitaire pour la ligne d'information.
  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(color: _textSecondary)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value.isEmpty ? '-' : value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  /// Methode utilitaire pour la ligne de securite.
  Widget _securityRow(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(Icons.shield_outlined, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(color: _textSecondary)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Methode utilitaire pour le separateur.
  Widget _sep() => const Divider(height: 16, color: _border);
}
