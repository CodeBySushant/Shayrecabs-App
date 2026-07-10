import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common.dart';
import 'auth_provider.dart';

/// Login — email+password or phone-OTP via WhatsApp (same two flows as web).
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.from});
  final String? from;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 2, vsync: this);

  // Email login
  final _emailForm = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  // Phone login
  final _phoneForm = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  bool _codeSent = false;

  bool _busy = false;

  @override
  void dispose() {
    _tab.dispose();
    _email.dispose();
    _password.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  void _onLoggedIn() {
    final from = widget.from;
    if (from != null && from.isNotEmpty) {
      context.go(from);
    } else {
      context.go('/');
    }
  }

  Future<void> _loginEmail() async {
    if (!_emailForm.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(authProvider.notifier)
          .login(_email.text.trim(), _password.text);
      if (mounted) _onLoggedIn();
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestPhoneCode() async {
    if (!_phoneForm.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .phoneLoginRequest(_phone.text.trim());
      setState(() => _codeSent = true);
      if (mounted) showAppSnack(context, 'Login code sent on WhatsApp.');
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyPhoneCode() async {
    if (Validators.otp(_code.text) != null) {
      showAppSnack(context, 'Enter the 6-digit code', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final (token, user) = await ref
          .read(authRepositoryProvider)
          .phoneLoginVerify(_phone.text.trim(), _code.text.trim());
      await ref.read(authProvider.notifier).applySession(token, user);
      if (mounted) _onLoggedIn();
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/shayrelogo.png', height: 56)
                      .animate()
                      .fadeIn()
                      .scale(begin: const Offset(.9, .9)),
                  const SizedBox(height: 20),
                  Text('Welcome back',
                      textAlign: TextAlign.center,
                      style: t.textTheme.headlineMedium),
                  const SizedBox(height: 6),
                  Text('Log in to book your shared ride',
                      textAlign: TextAlign.center,
                      style: t.textTheme.bodyMedium
                          ?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 24),
                  TabBar(
                    controller: _tab,
                    tabs: const [Tab(text: 'Email'), Tab(text: 'WhatsApp OTP')],
                  ),
                  const SizedBox(height: 20),
                  AnimatedBuilder(
                    animation: _tab,
                    builder: (_, __) => _tab.index == 0
                        ? _emailLogin(t)
                        : _phoneLogin(t),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('New to shayreCabs?',
                          style: t.textTheme.bodyMedium),
                      TextButton(
                        onPressed: () => context.push('/signup'),
                        child: const Text('Create account'),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Continue as guest'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emailLogin(ThemeData t) => Form(
        key: _emailForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              validator: Validators.email,
              decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email_rounded)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              validator: Validators.password,
              onFieldSubmitted: (_) => _loginEmail(),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot-password'),
                child: const Text('Forgot password?'),
              ),
            ),
            PrimaryButton(
                label: 'Log in', loading: _busy, onPressed: _loginEmail),
          ],
        ).animate().fadeIn(duration: 200.ms),
      );

  Widget _phoneLogin(ThemeData t) => Form(
        key: _phoneForm,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _phone,
              enabled: !_codeSent,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              validator: Validators.phone,
              decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '98XXXXXXXX',
                  prefixIcon: Icon(Icons.phone_iphone_rounded)),
            ),
            const SizedBox(height: 14),
            if (_codeSent) ...[
              TextFormField(
                controller: _code,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                    labelText: '6-digit code',
                    counterText: '',
                    prefixIcon: Icon(Icons.pin_rounded)),
              ).animate().fadeIn().moveY(begin: 8),
              const SizedBox(height: 8),
              PrimaryButton(
                  label: 'Verify & log in',
                  loading: _busy,
                  onPressed: _verifyPhoneCode),
              TextButton(
                onPressed: _busy ? null : _requestPhoneCode,
                child: const Text('Resend code'),
              ),
            ] else ...[
              Text(
                'Works for accounts with a verified phone number. '
                'The code arrives on WhatsApp.',
                style: t.textTheme.bodySmall
                    ?.copyWith(color: t.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                  label: 'Send WhatsApp code',
                  icon: Icons.chat_rounded,
                  color: AppColors.success,
                  loading: _busy,
                  onPressed: _requestPhoneCode),
            ],
          ],
        ).animate().fadeIn(duration: 200.ms),
      );
}
