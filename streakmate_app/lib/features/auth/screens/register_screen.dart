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

/// register_screen.dart
/// Maps directly to POST /auth/register body: { name, username, email, password }.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _nameError;
  String? _usernameError;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _nameError = Validators.name(_nameController.text);
      _usernameError = Validators.username(_usernameController.text);
      _emailError = Validators.email(_emailController.text);
      _passwordError = Validators.password(_passwordController.text);
    });

    return _nameError == null &&
        _usernameError == null &&
        _emailError == null &&
        _passwordError == null;
  }

  void _submit() {
    if (!_validate()) return;

    ref.read(authProvider.notifier).register(
      name: _nameController.text.trim(),
      username: _usernameController.text.trim().toLowerCase(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.authenticating;

    // Surface backend error (e.g. "Email already in use", "Username already
    // taken" — both 409 from authService) via SnackBar.
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppColors.danger,
          ),
        );
        ref.read(authProvider.notifier).clearError();
        return;
      }
      if (next.status == AuthStatus.unauthenticated && next.justRegistered) {
        context.go(RouteNames.login);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: isLoading ? null : () => context.go(RouteNames.login),
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.lightTextPrimary,
                ),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(alignment: Alignment.centerLeft),
              ),
              const SizedBox(height: 12),
              const Text(
                'Create your account',
                style: AppTextStyles.lightHeadline,
              ),
              const SizedBox(height: 8),
              const Text(
                'Small habits today, extraordinary life tomorrow.',
                style: AppTextStyles.lightSubtitle,
              ),
              const SizedBox(height: 28),

              AuthTextField(
                label: 'FULL NAME',
                controller: _nameController,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.person_outline,
                errorText: _nameError,
                autofillHints: const [AutofillHints.name],
                onChanged: (_) {
                  if (_nameError != null) {
                    setState(() => _nameError = null);
                  }
                },
              ),
              const SizedBox(height: 16),

              AuthTextField(
                label: 'USERNAME',
                controller: _usernameController,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.alternate_email,
                errorText: _usernameError,
                onChanged: (_) {
                  if (_usernameError != null) {
                    setState(() => _usernameError = null);
                  }
                },
              ),
              const SizedBox(height: 16),

              AuthTextField(
                label: 'EMAIL',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: Icons.mail_outline,
                errorText: _emailError,
                autofillHints: const [AutofillHints.email],
                onChanged: (_) {
                  if (_emailError != null) {
                    setState(() => _emailError = null);
                  }
                },
              ),
              const SizedBox(height: 16),

              AuthTextField(
                label: 'PASSWORD',
                controller: _passwordController,
                obscureText: true,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.lock_outline,
                errorText: _passwordError,
                autofillHints: const [AutofillHints.newPassword],
                onChanged: (_) {
                  if (_passwordError != null) {
                    setState(() => _passwordError = null);
                  }
                },
              ),

              const SizedBox(height: 28),

              AppButton(
                label: 'Create account',
                isLoading: isLoading,
                onPressed: _submit,
              ),

              const SizedBox(height: 20),

              Center(
                child: GestureDetector(
                  onTap: isLoading ? null : () => context.go(RouteNames.login),
                  child: RichText(
                    text: TextSpan(
                      style: AppTextStyles.lightSubtitle,
                      children: [
                        const TextSpan(
                          text: 'Already have an account? ',
                        ),
                        TextSpan(
                          text: 'Log in',
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