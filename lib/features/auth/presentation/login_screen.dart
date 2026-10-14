import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/ds/aeemg_buttons.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../data/auth_repository.dart';
import 'providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isSignUp = false;
  bool _otpSent = false;
  bool _isLoading = false;
  String? _otpEmail;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _signInWithPassword() async {
    if (!Env.isConfigured) {
      _showError('Supabase non configuré.');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final email = AuthRepository.normalizeEmail(_emailController.text);
      if (_isSignUp) {
        AuthRepository.validatePassword(_passwordController.text);
        final response = await ref
            .read(authRepositoryProvider)
            .signUpWithPassword(
              email: email,
              password: _passwordController.text,
              fullName: _nameController.text.trim().isEmpty
                  ? null
                  : _nameController.text.trim(),
            );
        if (!mounted) return;
        if (response.session != null) {
          context.go('/profile');
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response.user != null
                  ? 'Compte créé. Confirmez votre email avant de vous connecter.'
                  : 'Compte créé ! Vous pouvez vous connecter.',
            ),
            backgroundColor: AppColors.emerald,
          ),
        );
        setState(() => _isSignUp = false);
      } else {
        await ref
            .read(authRepositoryProvider)
            .signInWithPassword(
              email: email,
              password: _passwordController.text,
            );
        if (mounted) context.go('/profile');
      }
    } on AuthException catch (e) {
      _showError(friendlyAuthError(e.message));
    } catch (e) {
      _showError(friendlySupabaseError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);
    try {
      final email = AuthRepository.normalizeEmail(_emailController.text);
      await ref.read(authRepositoryProvider).sendEmailOtp(email);
      setState(() {
        _otpSent = true;
        _otpEmail = email;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email envoyé à $email.'),
            backgroundColor: AppColors.emerald,
          ),
        );
      }
    } on AuthException catch (e) {
      _showError(friendlyAuthError(e.message));
    } catch (e) {
      _showError(friendlySupabaseError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final email = _otpEmail;
    if (email == null) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyEmailOtp(email: email, token: _otpController.text.trim());
      if (mounted) context.go('/profile');
    } on AuthException catch (e) {
      _showError(friendlyAuthError(e.message));
    } catch (e) {
      _showError(friendlySupabaseError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    setState(() => _isLoading = true);
    try {
      final email = AuthRepository.normalizeEmail(_emailController.text);
      await ref.read(authRepositoryProvider).resetPasswordForEmail(email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email de réinitialisation envoyé à $email.'),
            backgroundColor: AppColors.emerald,
          ),
        );
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
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => context.go('/profile'),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mot de passe'),
            Tab(text: 'Code email'),
          ],
        ),
      ),
      body: IslamicBackground(
        withPattern: true,
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PasswordTab(
                emailController: _emailController,
                passwordController: _passwordController,
                nameController: _nameController,
                isSignUp: _isSignUp,
                isLoading: _isLoading,
                onToggleMode: () => setState(() => _isSignUp = !_isSignUp),
                onSubmit: _signInWithPassword,
                onResetPassword: _resetPassword,
              ),
              _OtpTab(
                emailController: _emailController,
                otpController: _otpController,
                otpSent: _otpSent,
                otpEmail: _otpEmail,
                isLoading: _isLoading,
                onSendOtp: _sendOtp,
                onVerifyOtp: _verifyOtp,
                onReset: () => setState(() {
                  _otpSent = false;
                  _otpEmail = null;
                  _otpController.clear();
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Champ du formulaire de connexion : style du thème (InputDecorationTheme).
InputDecoration _islamicInputDecoration(String label, IconData icon) {
  return InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20));
}

class _PasswordTab extends StatelessWidget {
  const _PasswordTab({
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
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkTeal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 28,
              color: AppColors.brightGreen,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          isSignUp ? 'Créer un compte' : 'Connexion',
          textAlign: TextAlign.center,
          style: AppTypography.h1.copyWith(fontSize: 28),
        ).animate(delay: 100.ms).fade(),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Bienvenue dans la communauté AEEMG',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ).animate(delay: 150.ms).fade(),
        const SizedBox(height: AppSpacing.xl),
        if (isSignUp) ...[
          TextField(
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(color: AppColors.white),
            decoration: _islamicInputDecoration(
              'Nom complet',
              Icons.person_outline,
            ),
          ).animate(delay: 200.ms).fade().slideY(begin: 0.1),
          const SizedBox(height: AppSpacing.md),
        ],
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          style: const TextStyle(color: AppColors.white),
          decoration: _islamicInputDecoration('Email', Icons.alternate_email),
        ).animate(delay: 250.ms).fade().slideY(begin: 0.1),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: passwordController,
          obscureText: true,
          style: const TextStyle(color: AppColors.white),
          decoration: _islamicInputDecoration(
            'Mot de passe',
            Icons.key_outlined,
          ),
        ).animate(delay: 300.ms).fade().slideY(begin: 0.1),
        const SizedBox(height: AppSpacing.xl),
        AeemgPrimaryButton(
          label: isSignUp ? 'Créer mon compte' : 'Se connecter',
          isLoading: isLoading,
          onPressed: onSubmit,
        ).animate(delay: 350.ms).fade().slideY(begin: 0.1),
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: onToggleMode,
          child: Text(
            isSignUp
                ? 'Déjà un compte ? Se connecter'
                : "Pas de compte ? S'inscrire",
          ),
        ).animate(delay: 400.ms).fade(),
        if (!isSignUp)
          TextButton(
            onPressed: isLoading ? null : onResetPassword,
            child: const Text(
              'Mot de passe oublié ?',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ).animate(delay: 450.ms).fade(),
      ],
    );
  }
}

class _OtpTab extends StatelessWidget {
  const _OtpTab({
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
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      physics: const BouncingScrollPhysics(),
      children: [
        const SizedBox(height: AppSpacing.xl),
        Center(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.darkTeal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.pin_outlined,
              size: 28,
              color: AppColors.brightGreen,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Code par email',
          textAlign: TextAlign.center,
          style: AppTypography.h1.copyWith(fontSize: 28),
        ).animate(delay: 100.ms).fade(),
        const SizedBox(height: AppSpacing.xs),
        Text(
          otpSent
              ? 'Code envoyé à $otpEmail'
              : 'Nécessite la configuration OTP dans Supabase.',
          textAlign: TextAlign.center,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ).animate(delay: 150.ms).fade(),
        const SizedBox(height: AppSpacing.xl),
        if (!otpSent) ...[
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.white),
            decoration: _islamicInputDecoration('Email', Icons.alternate_email),
          ).animate(delay: 200.ms).fade().slideY(begin: 0.1),
          const SizedBox(height: AppSpacing.lg),
          AeemgPrimaryButton(
            label: 'Recevoir le code',
            isLoading: isLoading,
            onPressed: onSendOtp,
          ).animate(delay: 250.ms).fade(),
        ] else ...[
          TextField(
            controller: otpController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 8,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: AppTypography.h2.copyWith(
              letterSpacing: 8,
              color: AppColors.white,
            ),
            decoration: InputDecoration(
              labelText: 'Code à 6 chiffres',
              hintText: '123456',
              counterText: '',
            ),
          ).animate(delay: 200.ms).fade().slideY(begin: 0.1),
          const SizedBox(height: AppSpacing.lg),
          AeemgPrimaryButton(
            label: 'Vérifier',
            isLoading: isLoading,
            onPressed: onVerifyOtp,
          ).animate(delay: 250.ms).fade(),
          TextButton(
            onPressed: onReset,
            child: const Text(
              "Changer d'email",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ).animate(delay: 300.ms).fade(),
        ],
      ],
    );
  }
}
