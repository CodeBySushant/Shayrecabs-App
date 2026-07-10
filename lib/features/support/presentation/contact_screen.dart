import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/auth_provider.dart';
import '../support_repository.dart';

/// Contact form — posts to the same public /support/contact endpoint the
/// web "Get in touch" form uses. Prefills name/email for logged-in users.
class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({super.key});

  @override
  ConsumerState<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends ConsumerState<ContactScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _email;
  final _subject = TextEditingController();
  final _message = TextEditingController();
  bool _busy = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _name = TextEditingController(text: user?.name ?? '');
    _email = TextEditingController(text: user?.email ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _subject.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(supportRepositoryProvider).contact(
            name: _name.text.trim(),
            email: _email.text.trim(),
            subject: _subject.text.trim(),
            message: _message.text.trim(),
          );
      setState(() => _sent = true);
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
      appBar: AppBar(title: const Text('Contact us')),
      body: _sent
          ? EmptyState(
              icon: Icons.mark_email_read_rounded,
              title: 'Message sent!',
              subtitle:
                  'Thanks for reaching out — our team replies within 24 hours '
                  'at the email you provided.',
              actionLabel: 'Done',
              onAction: () => Navigator.of(context).pop(),
            ).animate().fadeIn()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('We usually reply within a day',
                        style: t.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Or email us directly at ${AppConfig.supportEmail}',
                        style: t.textTheme.bodySmall?.copyWith(
                            color: t.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      validator: Validators.name,
                      decoration:
                          const InputDecoration(labelText: 'Your name'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.email,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _subject,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                          labelText: 'Subject (optional)'),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _message,
                      maxLines: 5,
                      textCapitalization: TextCapitalization.sentences,
                      validator: (v) => Validators.required(v, 'Message'),
                      decoration:
                          const InputDecoration(labelText: 'Your message'),
                    ),
                    const SizedBox(height: 22),
                    PrimaryButton(
                        label: 'Send message',
                        icon: Icons.send_rounded,
                        loading: _busy,
                        onPressed: _submit),
                  ],
                ),
              ),
            ),
    );
  }
}
