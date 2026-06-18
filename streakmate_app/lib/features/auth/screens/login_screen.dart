import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/router/route_names.dart';
import '../../../core/utils/validators.dart';
import '../../../providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../widgets/auth_text_field.dart';

/// login_screen.dart
/// Matches the light/illustrated onboarding aesthetic: warm off-white
/// background, rounded sprout-green primary button, soft card inputs.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = Validators.email(_emailController.text);
      _passwordError = _passwordController.text.isEmpty ? 'Password is required' : null;
    });
    return _emailError == null && _passwordError == null;
  }

  void _submit() {
    if (!_validate()) return;
    ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.authenticating;

    // Surface backend error (e.g. "Invalid email or password") via SnackBar.
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!), backgroundColor: AppColors.danger),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Logo mark — placeholder until brand asset is supplied ──
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.sproutGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Center(
                  child: Text('🔥', style: TextStyle(fontSize: 26)),
                ),
              ),
              const SizedBox(height: 28),
              const Text('Welcome back', style: AppTextStyles.lightHeadline),
              const SizedBox(height: 8),
              const Text(
                'Pick up right where you left your streak.',
                style: AppTextStyles.lightSubtitle,
              ),
              const SizedBox(height: 32),

              AuthTextField(
                label: 'EMAIL',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.mail_outline,
                errorText: _emailError,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) {
                  if (_emailError != null) setState(() => _emailError = null);
                },
              ),
              const SizedBox(height: 18),
              AuthTextField(
                label: 'PASSWORD',
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outline,
                errorText: _passwordError,
                autofillHints: const [AutofillHints.password],
                onChanged: (_) {
                  if (_passwordError != null) setState(() => _passwordError = null);
                },
              ),

              const SizedBox(height: 32),
              AppButton(
                label: 'Log in',
                isLoading: isLoading,
                onPressed: _submit,
              ),

              const SizedBox(height: 24),
              Center(
                child: GestureDetector(
                  onTap: isLoading ? null : () => context.go(RouteNames.register),
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.lightSubtitle,
                      children: [
                        const TextSpan(text: "Don't have an account? "),
                        TextSpan(
                          text: 'Sign up',
                          style: AppTextStyles.lightSubtitle.copyWith(
                            color: AppColors.sproutGreenDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}