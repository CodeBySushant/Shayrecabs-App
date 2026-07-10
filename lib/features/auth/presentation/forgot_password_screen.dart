import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/validators.dart';
import '../../../core/widgets/common.dart';
import 'auth_provider.dart';

/// Two-step reset: request a 6-digit email code, then set the new password —
/// same flow (and same generic success copy) as the website.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _code = TextEditingController();
  final _newPassword = TextEditingController();
  bool _codeStage = false;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _newPassword.dispose();
    super.dispose();
  }

  Future<void> _requestCode() async {
    if (Validators.email(_email.text) != null) {
      showAppSnack(context, 'Enter a valid email address', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).forgotPassword(_email.text.trim());
      setState(() => _codeStage = true);
      if (mounted) {
        showAppSnack(context,
            'If an account exists for that email, a reset code has been sent.');
      }
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authRepositoryProvider).resetPassword(
            email: _email.text.trim(),
            code: _code.text.trim(),
            newPassword: _newPassword.text,
          );
      if (mounted) {
        showAppSnack(context, 'Password reset successful. You can now log in.');
        context.go('/login');
      }
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Reset password')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.lock_reset_rounded,
                            size: 56, color: t.colorScheme.primary)
                        .animate()
                        .scale(curve: Curves.easeOutBack),
                    const SizedBox(height: 16),
                    Text(
                      _codeStage
                          ? 'Enter the code we emailed you'
                          : 'We\'ll email you a 6-digit reset code',
                      textAlign: TextAlign.center,
                      style: t.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _email,
                      enabled: !_codeStage,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.alternate_email_rounded)),
                    ),
                    if (_codeStage) ...[
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _code,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        validator: Validators.otp,
                        decoration: const InputDecoration(
                            labelText: '6-digit code',
                            counterText: '',
                            prefixIcon: Icon(Icons.pin_rounded)),
                      ).animate().fadeIn().moveY(begin: 8),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _newPassword,
                        obscureText: _obscure,
                        validator: Validators.password,
                        decoration: InputDecoration(
                          labelText: 'New password (min 6 characters)',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(_obscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ).animate().fadeIn(delay: 60.ms).moveY(begin: 8),
                    ],
                    const SizedBox(height: 22),
                    if (_codeStage) ...[
                      PrimaryButton(
                          label: 'Reset password',
                          loading: _busy,
                          onPressed: _reset),
                      TextButton(
                        onPressed: _busy ? null : _requestCode,
                        child: const Text('Resend code'),
                      ),
                    ] else
                      PrimaryButton(
                          label: 'Send reset code',
                          loading: _busy,
                          onPressed: _requestCode),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
