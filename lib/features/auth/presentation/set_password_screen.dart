import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
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
          const SnackBar(content: Text('Mot de passe enregistré.'), backgroundColor: AppColors.emerald),
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

  InputDecoration _islamicInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.emerald),
      filled: true,
      fillColor: AppColors.cardSurface.withValues(alpha: 0.6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.emerald.withValues(alpha: 0.6)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text('Sécurité', style: AppTypography.h2.copyWith(color: AppColors.white)),
      ),
      body: IslamicBackground(
        withPattern: true,
        child: ListView(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.xl,
          ),
          physics: const BouncingScrollPhysics(),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald.withValues(alpha: 0.15),
                  border: Border.all(color: AppColors.emerald.withValues(alpha: 0.4), width: 2),
                  boxShadow: [BoxShadow(color: AppColors.emerald.withValues(alpha: 0.2), blurRadius: 20)],
                ),
                child: const Icon(Icons.shield_outlined, size: 48, color: AppColors.emerald),
              ).animate().scale(curve: Curves.easeOutBack),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Définir un mot de passe',
              textAlign: TextAlign.center,
              style: AppTypography.h1.copyWith(fontSize: 26),
            ).animate(delay: 100.ms).fade(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              "Utile si vous vous êtes connecté par code email. "
              "Ensuite vous pourrez utiliser l'onglet Mot de passe.",
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ).animate(delay: 150.ms).fade(),
            const SizedBox(height: AppSpacing.xl),

            TextField(
              controller: _passwordController,
              obscureText: true,
              style: const TextStyle(color: AppColors.white),
              decoration: _islamicInputDecoration('Nouveau mot de passe', Icons.key_outlined),
            ).animate(delay: 200.ms).fade().slideY(begin: 0.1),
            const SizedBox(height: AppSpacing.md),

            TextField(
              controller: _confirmController,
              obscureText: true,
              style: const TextStyle(color: AppColors.white),
              decoration: _islamicInputDecoration('Confirmer le mot de passe', Icons.lock_reset),
            ).animate(delay: 300.ms).fade().slideY(begin: 0.1),
            const SizedBox(height: AppSpacing.xl),

            AeemgPrimaryButton(
              label: 'Enregistrer le mot de passe',
              icon: Icons.check,
              isLoading: _isLoading,
              onPressed: _save,
            ).animate(delay: 400.ms).fade().slideY(begin: 0.1),
          ],
        ),
      ),
    );
  }
}
