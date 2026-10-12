import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../data/admin_repository.dart';

class AdminIslamicDialog extends ConsumerStatefulWidget {
  const AdminIslamicDialog({super.key, required this.repository, required this.onSuccess});
  
  final AdminRepository repository;
  final VoidCallback onSuccess;

  @override
  ConsumerState<AdminIslamicDialog> createState() => _AdminIslamicDialogState();
}

class _AdminIslamicDialogState extends ConsumerState<AdminIslamicDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _sourceController = TextEditingController();
  final _translationController = TextEditingController();
  String _contentType = 'verse';
  bool _isLoading = false;

  final Map<String, String> _types = {
    'verse': 'Verset du Coran',
    'hadith': 'Hadith',
    'quote': 'Citation / Conseil',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _sourceController.dispose();
    _translationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le contenu est obligatoire'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.repository.createIslamicContent(
        title: _titleController.text.trim().isEmpty ? 'Sans titre' : _titleController.text.trim(),
        body: body,
        contentType: _contentType,
        source: _sourceController.text.trim().isEmpty ? null : _sourceController.text.trim(),
        translationPeul: _translationController.text.trim().isEmpty ? null : _translationController.text.trim(),
      );
      if (mounted) {
        context.pop();
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contenu ajouté avec succès'), backgroundColor: AppColors.gold),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _deco(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.gold) : null,
      filled: true,
      fillColor: AppColors.cardSurfaceLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: AppColors.gold.withValues(alpha: 0.3))),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: AppColors.gold.withValues(alpha: 0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.auto_stories, color: AppColors.gold),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: Text('Nouveau contenu', style: AppTypography.h2)),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              DropdownButtonFormField<String>(
                initialValue: _contentType,
                dropdownColor: AppColors.cardSurfaceLight,
                decoration: _deco('Type de contenu', icon: Icons.category),
                items: _types.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(color: AppColors.white)))).toList(),
                onChanged: (val) => setState(() => _contentType = val!),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _titleController,
                style: const TextStyle(color: AppColors.white),
                decoration: _deco('Titre (optionnel)', icon: Icons.title),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _bodyController,
                maxLines: 4,
                style: const TextStyle(color: AppColors.white),
                decoration: _deco('Contenu (Arabe / Français) *'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _sourceController,
                style: const TextStyle(color: AppColors.white),
                decoration: _deco('Source (ex: Sourate Al-Baqarah, Ayat 255)', icon: Icons.menu_book),
              ),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _translationController,
                maxLines: 2,
                style: const TextStyle(color: AppColors.white),
                decoration: _deco('Traduction ou explication en Peul (optionnel)', icon: Icons.language),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  AeemgPrimaryButton(
                    label: 'Ajouter',
                    isLoading: _isLoading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
