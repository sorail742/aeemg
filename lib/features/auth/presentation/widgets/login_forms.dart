import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../../../shared/widgets/ds/aeemg_card.dart';
import '../../../../shared/widgets/ds/aeemg_password_field.dart';

/// En-tête de la connexion : logo cerclé d'or avec halo, salutation et accroche.
class LoginBrand extends StatelessWidget {
  const LoginBrand({super.key});

  static const double _logoSize = 76;

  @override
  Widget build(BuildContext context) {
    final cacheSize = (_logoSize * MediaQuery.devicePixelRatioOf(context))
        .round();
    return Column(
      children: [
        Container(
          width: _logoSize,
          height: _logoSize,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: 0.35),
                blurRadius: 28,
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/images/aeemg_logo.png',
              fit: BoxFit.cover,
              cacheWidth: cacheSize,
              semanticLabel: 'Logo AEEMG',
              errorBuilder: (_, _, _) => const ColoredBox(
                color: AppColors.darkTeal,
                child: Icon(Icons.mosque_rounded, color: AppColors.gold),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'ASSALAMOU ALAYKOUM',
          style: AppTypography.caption.copyWith(
            color: AppColors.gold,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Bienvenue dans la communauté AEEMG',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall,
        ),
      ],
    );
  }
}

/// Carte de formulaire : titre, explication, puis les champs et les actions.
class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AeemgCard(
      padding: const EdgeInsets.all(AppSpacing.mdLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: AppTypography.h2),
          const SizedBox(height: AppSpacing.xs),
          Text(subtitle, style: AppTypography.bodySmall),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
}

class LoginPasswordForm extends StatelessWidget {
  const LoginPasswordForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.nameController,
    required this.isSignUp,
    required this.isLoading,
    required this.onToggleMode,
    required this.onSubmit,
    required this.onResetPassword,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController nameController;
  final bool isSignUp;
  final bool isLoading;
  final VoidCallback onToggleMode;
  final VoidCallback onSubmit;
  final VoidCallback onResetPassword;

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: _FormCard(
        title: isSignUp ? 'Créer un compte' : 'Connexion',
        subtitle: isSignUp
            ? 'Rejoignez la communauté en quelques secondes.'
            : 'Avec votre email et votre mot de passe.',
        children: [
          if (isSignUp) ...[
            TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(
                labelText: 'Nom complet',
                prefixIcon: Icon(Icons.person_outline, size: 20),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.next,
            autofillHints: const [AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.alternate_email, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AeemgPasswordField(
            controller: passwordController,
            label: 'Mot de passe',
            autofillHints: [
              isSignUp ? AutofillHints.newPassword : AutofillHints.password,
            ],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => isLoading ? null : onSubmit(),
          ),
          const SizedBox(height: AppSpacing.lg),
          AeemgPrimaryButton(
            label: isSignUp ? 'Créer mon compte' : 'Se connecter',
            isLoading: isLoading,
            onPressed: onSubmit,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onToggleMode,
            child: Text(
              isSignUp
                  ? 'Déjà un compte ? Se connecter'
                  : "Pas de compte ? S'inscrire",
            ),
          ),
          if (!isSignUp)
            TextButton(
              onPressed: isLoading ? null : onResetPassword,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
              child: const Text('Mot de passe oublié ?'),
            ),
        ],
      ),
    );
  }
}

class LoginOtpForm extends StatelessWidget {
  const LoginOtpForm({
    super.key,
    required this.emailController,
    required this.otpController,
    required this.otpSent,
    required this.otpEmail,
    required this.isLoading,
    required this.onSendOtp,
    required this.onVerifyOtp,
    required this.onReset,
  });

  final TextEditingController emailController;
  final TextEditingController otpController;
  final bool otpSent;
  final String? otpEmail;
  final bool isLoading;
  final VoidCallback onSendOtp;
  final VoidCallback onVerifyOtp;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return _FormCard(
      title: 'Code par email',
      subtitle: otpSent
          ? 'Code envoyé à $otpEmail'
          : 'Recevez un code à usage unique, sans mot de passe.',
      children: [
        if (!otpSent) ...[
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.send,
            autofillHints: const [AutofillHints.email],
            onSubmitted: (_) => isLoading ? null : onSendOtp(),
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.alternate_email, size: 20),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AeemgPrimaryButton(
            label: 'Recevoir le code',
            isLoading: isLoading,
            onPressed: onSendOtp,
          ),
        ] else ...[
          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 8,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => isLoading ? null : onVerifyOtp(),
            style: AppTypography.h2.copyWith(letterSpacing: 8),
            decoration: const InputDecoration(
              labelText: 'Code à 6 chiffres',
              hintText: '123456',
              counterText: '',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AeemgPrimaryButton(
            label: 'Vérifier',
            isLoading: isLoading,
            onPressed: onVerifyOtp,
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: onReset,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
            child: const Text("Changer d'email"),
          ),
        ],
      ],
    );
  }
}
