import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../../shared/widgets/ds/aeemg_card.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import 'providers/members_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _sectionController = TextEditingController();
  final _specialtyController = TextEditingController();
  bool _isPublic = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sectionController.dispose();
    _specialtyController.dispose();
    super.dispose();
  }

  Future<void> _save(String userId) async {
    setState(() => _isSaving = true);
    try {
      await ref.read(membersRepositoryProvider).updateProfile(userId, {
        'full_name': _nameController.text.trim(),
        'section': _sectionController.text.trim().isEmpty ? null : _sectionController.text.trim(),
        'specialty': _specialtyController.text.trim().isEmpty ? null : _specialtyController.text.trim(),
        'is_profile_public': _isPublic,
      });
      ref.invalidate(myProfileProvider);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur : $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _islamicInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: Icon(icon, color: AppColors.gold),
      filled: true,
      fillColor: AppColors.cardSurface.withValues(alpha: 0.6),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.6)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: AppColors.background.withValues(alpha: 0.9),
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Text('Modifier le profil', style: AppTypography.h2.copyWith(color: AppColors.white)),
      ),
      body: IslamicBackground(
        withPattern: true,
        child: AsyncValueWidget(
          value: profileAsync,
          loading: const Center(child: CircularProgressIndicator(color: AppColors.emerald)),
          data: (profile) {
            if (profile != null && _nameController.text.isEmpty) {
              _nameController.text = profile.fullName;
              _sectionController.text = profile.section ?? '';
              _specialtyController.text = profile.specialty ?? '';
              _isPublic = profile.isProfilePublic;
            }

            return ListView(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.xl,
              ),
              physics: const BouncingScrollPhysics(),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.gold.withValues(alpha: 0.15),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 2),
                      boxShadow: [BoxShadow(color: AppColors.gold.withValues(alpha: 0.2), blurRadius: 20)],
                    ),
                    child: const Icon(Icons.manage_accounts, size: 48, color: AppColors.gold),
                  ).animate().scale(curve: Curves.easeOutBack),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Informations personnelles',
                  textAlign: TextAlign.center,
                  style: AppTypography.h3.copyWith(color: AppColors.gold),
                ).animate(delay: 100.ms).fade(),
                const SizedBox(height: AppSpacing.xl),

                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: _islamicInputDecoration('Nom complet', Icons.person_outline),
                ).animate(delay: 200.ms).fade().slideY(begin: 0.1),
                const SizedBox(height: AppSpacing.md),

                TextField(
                  controller: _sectionController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: _islamicInputDecoration('Section (Ex: Conakry)', Icons.location_on_outlined),
                ).animate(delay: 300.ms).fade().slideY(begin: 0.1),
                const SizedBox(height: AppSpacing.md),

                TextField(
                  controller: _specialtyController,
                  style: const TextStyle(color: AppColors.white),
                  decoration: _islamicInputDecoration('Spécialité (Ex: Informatique)', Icons.school_outlined),
                ).animate(delay: 400.ms).fade().slideY(begin: 0.1),
                const SizedBox(height: AppSpacing.lg),

                AeemgCard(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.emerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.visibility_outlined, color: AppColors.emerald, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Profil public', style: AppTypography.h3),
                            const SizedBox(height: 2),
                            Text(
                              "Visible dans l'annuaire des membres",
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isPublic,
                        onChanged: (v) => setState(() => _isPublic = v),
                        activeThumbColor: AppColors.emerald,
                        activeTrackColor: AppColors.emerald.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ).animate(delay: 500.ms).fade().slideY(begin: 0.1),
                const SizedBox(height: AppSpacing.xl),

                AeemgPrimaryButton(
                  label: 'Enregistrer les modifications',
                  icon: Icons.check_circle_outline,
                  isLoading: _isSaving,
                  onPressed: _isSaving || user == null ? null : () => _save(user.id),
                ).animate(delay: 600.ms).fade().slideY(begin: 0.1),
              ],
            );
          },
        ),
      ),
    );
  }
}
