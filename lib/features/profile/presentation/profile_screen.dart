import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/auth_provider.dart';

/// Profile — edit details, email/phone OTP verification, selfie KYC,
/// change password, theme, logout. Feature parity with the web Profile page.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _busy = false;

  Future<void> _guard(Future<void> Function() op) async {
    setState(() => _busy = true);
    try {
      await op();
    } catch (e) {
      if (mounted) showAppSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // ── Edit profile ──
  Future<void> _editProfile() async {
    final user = ref.read(authProvider).user!;
    final name = TextEditingController(text: user.name);
    final phone = TextEditingController(text: user.phone ?? '');
    String? gender = user.gender;
    final genderLocked = user.verified.govId;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: StatefulBuilder(
              builder: (ctx, setSheet) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Edit profile',
                      style: Theme.of(ctx).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  TextField(
                      controller: name,
                      textCapitalization: TextCapitalization.words,
                      decoration:
                          const InputDecoration(labelText: 'Full name')),
                  const SizedBox(height: 12),
                  TextField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                          labelText: 'Phone',
                          helperText:
                              'Changing your phone resets phone verification')),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: InputDecoration(
                      labelText: 'Gender',
                      helperText: genderLocked
                          ? 'Locked after KYC verification — contact support to change'
                          : null,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged:
                        genderLocked ? null : (v) => setSheet(() => gender = v),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Save changes')),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (saved != true) return;
    await _guard(() async {
      final updated = await ref.read(authRepositoryProvider).updateProfile(
            name: name.text.trim(),
            phone: phone.text.trim(),
            gender: gender,
          );
      ref.read(authProvider.notifier).updateUser(updated);
      if (mounted) showAppSnack(context, 'Profile updated');
    });
  }

  // ── OTP verification sheet (shared by email + phone) ──
  Future<void> _verifyOtpFlow({
    required String title,
    required String sentMessage,
    required Future<bool> Function() request,
    required Future<void> Function(String code) verify,
  }) async {
    await _guard(() async {
      final delivered = await request();
      if (!mounted) return;
      showAppSnack(
          context,
          delivered
              ? sentMessage
              : 'Code generated — delivery channel not configured, contact support.');
    });
    if (!mounted) return;

    final code = TextEditingController();
    final entered = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(title, style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 14),
                TextField(
                  controller: code,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                      labelText: '6-digit code', counterText: ''),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, code.text.trim()),
                  child: const Text('Verify'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (entered == null || Validators.otp(entered) != null) return;
    await _guard(() async {
      await verify(entered);
      if (mounted) showAppSnack(context, 'Verified successfully!');
    });
  }

  // ── Selfie KYC ──
  Future<void> _submitKyc() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Take a selfie'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
      maxWidth: 1080,
      imageQuality: 85, // stays well under the backend's 5MB limit
    );
    if (picked == null) return;

    await _guard(() async {
      final updated =
          await ref.read(authRepositoryProvider).submitSelfie(picked.path);
      ref.read(authProvider.notifier).updateUser(updated);
      if (mounted) {
        showAppSnack(context,
            'Selfie submitted — our team reviews it within 24 hours.');
      }
    });
  }

  // ── Change password ──
  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Change password',
                    style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 14),
                TextField(
                    controller: current,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Current password')),
                const SizedBox(height: 12),
                TextField(
                    controller: next,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'New password (min 6 characters)')),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Update password')),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true) return;
    if (Validators.password(next.text) != null) {
      showAppSnack(context, 'New password must be at least 6 characters',
          error: true);
      return;
    }
    await _guard(() async {
      await ref.read(authRepositoryProvider).changePassword(
          currentPassword: current.text, newPassword: next.text);
      if (mounted) showAppSnack(context, 'Password updated');
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final themeMode = ref.watch(themeModeProvider);

    if (user == null) return const SizedBox.shrink(); // router redirects

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(authProvider.notifier).refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Identity card ──
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.brand.withOpacity(.12),
                      child: Text(
                        user.name.isEmpty
                            ? '?'
                            : user.name.characters.first.toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.brand,
                            fontSize: 24,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: t.textTheme.titleLarge),
                          Text(user.email, style: t.textTheme.bodySmall),
                          if (user.phone != null)
                            Text(user.phone!, style: t.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _busy ? null : _editProfile,
                      icon: const Icon(Icons.edit_rounded),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn().moveY(begin: 8),

            const SectionHeader('Verifications'),

            _VerifyTile(
              icon: Icons.alternate_email_rounded,
              title: 'Email',
              verified: user.verified.email,
              onVerify: () => _verifyOtpFlow(
                title: 'Verify your email',
                sentMessage: 'Verification code sent to your email.',
                request: () => ref.read(authRepositoryProvider).requestEmailOtp(),
                verify: (code) async {
                  final u = await ref
                      .read(authRepositoryProvider)
                      .verifyEmailOtp(code);
                  ref.read(authProvider.notifier).updateUser(u);
                },
              ),
            ),
            _VerifyTile(
              icon: Icons.phone_iphone_rounded,
              title: 'Phone (WhatsApp OTP)',
              verified: user.verified.phone,
              onVerify: () => _verifyOtpFlow(
                title: 'Verify your phone',
                sentMessage: 'Verification code sent on WhatsApp.',
                request: () => ref
                    .read(authRepositoryProvider)
                    .requestPhoneOtp(user.phone ?? ''),
                verify: (code) async {
                  final u = await ref
                      .read(authRepositoryProvider)
                      .verifyPhoneOtp(code);
                  ref.read(authProvider.notifier).updateUser(u);
                },
              ),
            ),

            // ── KYC ──
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            color: AppColors.brand),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text('Identity (selfie KYC)',
                                style: t.textTheme.titleMedium)),
                        StatusChip(user.verified.govId
                            ? 'verified'
                            : user.kyc.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      switch (user.kyc.status) {
                        'verified' =>
                          'You\'re verified! Women-only rides are unlocked for verified female profiles.',
                        'pending' =>
                          'Your selfie is under review — this usually takes under 24 hours.',
                        'rejected' =>
                          'Submission rejected${user.kyc.rejectionReason != null ? ': ${user.kyc.rejectionReason}' : ''}. You can submit a new selfie.',
                        _ =>
                          'Submit a selfie to get verified. No government ID is collected, and selfies are auto-deleted after 30 days.',
                      },
                      style: t.textTheme.bodySmall?.copyWith(
                          color: t.colorScheme.onSurfaceVariant, height: 1.4),
                    ),
                    if (user.kyc.status == 'none' ||
                        user.kyc.status == 'rejected') ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _submitKyc,
                        icon: const Icon(Icons.camera_front_rounded, size: 20),
                        label: const Text('Submit selfie'),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SectionHeader('Settings'),

            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.dark_mode_rounded),
                    title: const Text('Appearance'),
                    trailing: SegmentedButton<ThemeMode>(
                      style: const ButtonStyle(
                          visualDensity: VisualDensity.compact),
                      segments: const [
                        ButtonSegment(
                            value: ThemeMode.light,
                            icon: Icon(Icons.light_mode_rounded, size: 18)),
                        ButtonSegment(
                            value: ThemeMode.system,
                            icon: Icon(Icons.brightness_auto_rounded, size: 18)),
                        ButtonSegment(
                            value: ThemeMode.dark,
                            icon: Icon(Icons.dark_mode_rounded, size: 18)),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (s) =>
                          ref.read(themeModeProvider.notifier).set(s.first),
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.lock_rounded),
                    title: const Text('Change password'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: _busy ? null : _changePassword,
                  ),
                ],
              ),
            ),

            const SectionHeader('Support & legal'),
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Column(children: [
                _link(context, Icons.support_agent_rounded, 'Contact us', '/contact'),
                _link(context, Icons.help_center_rounded, 'Help center', '/help'),
                _link(context, Icons.health_and_safety_rounded, 'Safety', '/safety'),
                _link(context, Icons.info_rounded, 'About shayreCabs', '/about'),
                _link(context, Icons.description_rounded, 'Terms of service', '/terms'),
                _link(context, Icons.currency_rupee_rounded, 'Refund policy', '/refund-policy'),
              ]),
            ),

            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) context.go('/');
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                side: BorderSide(color: AppColors.danger.withOpacity(.5)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Log out'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _link(BuildContext context, IconData icon, String label, String path) =>
      ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: () => context.push(path),
      );
}

class _VerifyTile extends StatelessWidget {
  const _VerifyTile({
    required this.icon,
    required this.title,
    required this.verified,
    required this.onVerify,
  });

  final IconData icon;
  final String title;
  final bool verified;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: Icon(icon,
              color: verified ? AppColors.success : AppColors.brand),
          title: Text(title),
          trailing: verified
              ? const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified_rounded,
                      color: AppColors.success, size: 20),
                  SizedBox(width: 4),
                  Text('Verified',
                      style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600)),
                ])
              : FilledButton.tonal(
                  onPressed: onVerify, child: const Text('Verify')),
        ),
      );
}
