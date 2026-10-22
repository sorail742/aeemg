import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../../core/router/route_guard.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_motion.dart';
import '../../../core/utils/supabase_errors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/ds/aeemg_motion.dart';
import '../../../shared/widgets/ds/aeemg_pill_tab_bar.dart';
import '../../../shared/widgets/ds/islamic_background.dart';
import '../data/auth_repository.dart';
import 'providers/auth_provider.dart';
import 'widgets/login_forms.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// Page demandée avant la redirection vers la connexion (SEC-024), sinon le profil.
  String get _afterLogin =>
      safeReturnPath(GoRouterState.of(context).uri.queryParameters['from']) ??
      '/profile';

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
          context.go(_afterLogin);
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
        if (mounted) context.go(_afterLogin);
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
      if (mounted) context.go(_afterLogin);
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
    final sections = <Widget>[
      Align(
        alignment: Alignment.centerLeft,
        child: AeemgRoundIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'Retour',
          onPressed: () => context.go('/profile'),
        ),
      ),
      const LoginBrand(),
      const SizedBox(height: AppSpacing.lg),
      AeemgPillTabBar(
        controller: _tabController,
        labels: const ['Mot de passe', 'Code email'],
      ),
      const SizedBox(height: AppSpacing.md),
      // Un seul formulaire à la fois, dans la même liste : le clavier fait défiler
      // toute la page, sans glissement horizontal entre deux formulaires.
      AnimatedBuilder(
        animation: _tabController,
        builder: (context, _) => AnimatedSwitcher(
          duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.base,
          child: _tabController.index == 0
              ? LoginPasswordForm(
                  key: const ValueKey('password'),
                  emailController: _emailController,
                  passwordController: _passwordController,
                  nameController: _nameController,
                  isSignUp: _isSignUp,
                  isLoading: _isLoading,
                  onToggleMode: () => setState(() => _isSignUp = !_isSignUp),
                  onSubmit: _signInWithPassword,
                  onResetPassword: _resetPassword,
                )
              : LoginOtpForm(
                  key: const ValueKey('otp'),
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
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IslamicBackground(
        withPattern: true,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm + MediaQuery.paddingOf(context).top,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          children: [
            for (var i = 0; i < sections.length; i++)
              sections[i].reveal(context, index: i),
          ],
        ),
      ),
    );
  }
}
