import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/aeemg_page.dart';
import '../../../shared/widgets/ds/aeemg_password_field.dart';
import '../data/auth_repository.dart';
import 'providers/auth_provider.dart';

class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password != confirm) {
      _showError('Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      AuthRepository.validatePassword(password);
      await ref.read(authRepositoryProvider).updatePassword(password);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe enregistré.'),
            backgroundColor: AppColors.emerald,
          ),
        );
        context.pop();
      }
    } on AuthException catch (e) {
      _showError(friendlyAuthError(e.message));
    } catch (e) {
      _showError(friendlySupabaseError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AeemgPage(
      title: 'Définir un mot de passe',
      subtitle:
          'Utile si vous vous êtes connecté par code email. Ensuite, '
          "l'onglet Mot de passe de la connexion fonctionnera aussi.",
      children: [
        AutofillGroup(
          child: AeemgCard(
            padding: const EdgeInsets.all(AppSpacing.mdLg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AeemgPasswordField(
                  controller: _passwordController,
                  label: 'Nouveau mot de passe',
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                AeemgPasswordField(
                  controller: _confirmController,
                  label: 'Confirmer le mot de passe',
                  icon: Icons.lock_reset,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _isLoading ? null : _save(),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Au moins ${AuthRepository.minPasswordLength} caractères, '
                  'avec des lettres et des chiffres.',
                  style: AppTypography.caption,
                ),
                const SizedBox(height: AppSpacing.lg),
                AeemgPrimaryButton(
                  label: 'Enregistrer le mot de passe',
                  icon: Icons.check,
                  isLoading: _isLoading,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
