import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Static content pages — Safety, About, Help Center, Terms, Refund Policy.
/// Content mirrors the web pages, condensed for mobile reading.

class _InfoScaffold extends StatelessWidget {
  const _InfoScaffold({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: ListView(padding: const EdgeInsets.all(20), children: children),
      );
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({this.icon, required this.title, required this.body});
  final IconData? icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.brand, size: 22),
                const SizedBox(width: 10),
              ],
              Expanded(child: Text(title, style: t.textTheme.titleMedium)),
            ]),
            const SizedBox(height: 8),
            Text(body,
                style: t.textTheme.bodyMedium?.copyWith(
                    height: 1.5, color: t.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ── Safety ──
class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) => const _InfoScaffold(
        title: 'Safety at shayreCabs',
        children: [
          _InfoBlock(
            icon: Icons.verified_user_rounded,
            title: 'Verified co-riders',
            body:
                'Riders can verify their identity with a quick selfie review. '
                'Verified profiles carry a badge so you always know who you\'re '
                'sharing with. No government ID is ever collected, and selfies '
                'are automatically deleted after 30 days.',
          ),
          _InfoBlock(
            icon: Icons.female_rounded,
            title: 'Women-only rides',
            body:
                'Women-only rides are restricted to KYC-verified female profiles '
                '— enforced server-side, not just a filter. Women drivers are '
                'assigned where available.',
          ),
          _InfoBlock(
            icon: Icons.badge_rounded,
            title: 'Screened drivers',
            body:
                'Every driver on the platform is onboarded with vehicle and '
                'license checks, and carries a public rating from riders.',
          ),
          _InfoBlock(
            icon: Icons.schedule_rounded,
            title: 'Fixed, scheduled departures',
            body:
                'No surge, no waiting on a curb at midnight. Rides run on fixed '
                'schedules with a known route, known co-riders, and a known fare '
                'before you pay.',
          ),
          _InfoBlock(
            icon: Icons.support_agent_rounded,
            title: '24×7 support',
            body:
                'File a complaint from your bookings or contact us anytime — '
                'high-priority safety issues are escalated immediately.',
          ),
        ],
      );
}

// ── About ──
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => const _InfoScaffold(
        title: 'About shayreCabs',
        children: [
          _InfoBlock(
            icon: Icons.flight_takeoff_rounded,
            title: 'What we do',
            body:
                'shayreCabs runs scheduled shared cabs between IGI Airport, '
                'Noida and Gurugram — plus direct Noida ⇄ Gurugram intercity '
                'rides. You book a seat, not a cab, and the fare is split per '
                'person.',
          ),
          _InfoBlock(
            icon: Icons.savings_rounded,
            title: 'Why shared',
            body:
                'A solo airport cab on the same route costs 2–3× more. Sharing '
                'a scheduled ride saves up to 60% while keeping fixed timings '
                'and door-drop hotspots.',
          ),
          _InfoBlock(
            icon: Icons.route_rounded,
            title: 'Corridors we cover',
            body:
                'IGI → Noida (Expressway, Central, Extension corridors), '
                'IGI → Gurugram (Arterial, Golf Course, West corridors), and '
                'Noida ⇄ Gurugram intercity with hotspot pickups.',
          ),
          _InfoBlock(
            icon: Icons.groups_rounded,
            title: 'Community first',
            body:
                'Destination and area-based WhatsApp communities keep frequent '
                'flyers connected — including women-only groups.',
          ),
        ],
      );
}

// ── Help Center (FAQ) ──
class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _faqs = [
    (
      'How does seat booking work?',
      'Pick a scheduled ride, choose your sharing type and drop point, and pay '
          'for one seat. Your fare is per person — it\'s never multiplied by '
          'the number of co-riders.'
    ),
    (
      'What if my payment fails?',
      'Your seat stays held for 1 hour. Open My Bookings and tap "Pay now" to '
          'retry. If you don\'t pay within the hour, the booking auto-cancels '
          'and the seat is released — nothing is charged.'
    ),
    (
      'What\'s the cancellation policy?',
      'Cancel more than 24h before departure: full refund minus a flat ₹200. '
          '12–24h before: 50% refund. Less than 12h: no refund. Unpaid '
          'bookings can be cancelled free anytime.'
    ),
    (
      'Who can book women-only rides?',
      'Only KYC-verified female profiles. Complete the selfie verification in '
          'your Profile — review usually takes under 24 hours.'
    ),
    (
      'How do I get my OTPs?',
      'Login and phone-verification codes arrive on WhatsApp. Email '
          'verification and password-reset codes arrive by email. Codes expire '
          'in 10 minutes, with up to 5 requests per day.'
    ),
    (
      'Where exactly is the pickup at IGI?',
      'Your booking confirmation includes the terminal pickup point. Add your '
          'flight number while booking so the driver can track delays.'
    ),
    (
      'When can I rate my ride?',
      'Rating unlocks automatically once your ride\'s departure time has '
          'passed on a paid booking — find it in My Bookings.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help center')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (q, a) in _faqs)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ExpansionTile(
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                title: Text(q,
                    style: Theme.of(context).textTheme.titleSmall),
                childrenPadding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  Text(a,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                              height: 1.5,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Terms ──
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _InfoScaffold(
        title: 'Terms of service',
        children: [
          _InfoBlock(
            title: '1. The service',
            body:
                'shayreCabs provides scheduled shared cab rides between IGI '
                'Airport, Noida and Gurugram. A booking reserves one seat on a '
                'scheduled ride at the per-person fare shown at checkout.',
          ),
          _InfoBlock(
            title: '2. Accounts & verification',
            body:
                'You must provide accurate details at signup. Phone and email '
                'verification use one-time codes. Identity (selfie) verification '
                'is optional except for women-only rides, where a verified '
                'female profile is mandatory. Gender is locked after verification.',
          ),
          _InfoBlock(
            title: '3. Payments',
            body:
                'Payments are processed by Razorpay. The fare charged is the '
                'server-computed per-person fare for your route, drop point and '
                'sharing type. Unpaid bookings hold a seat for 1 hour, after '
                'which they auto-cancel.',
          ),
          _InfoBlock(
            title: '4. Cancellations & refunds',
            body:
                'Refunds follow the published refund policy bands based on time '
                'before departure. Refunds are processed to the original payment '
                'method after review.',
          ),
          _InfoBlock(
            title: '5. Conduct',
            body:
                'Riders must be at the pickup point on time; rides depart on '
                'schedule. Abusive behaviour toward drivers or co-riders leads '
                'to account suspension.',
          ),
        ],
      );
}

// ── Refund policy ──
class RefundPolicyScreen extends StatelessWidget {
  const RefundPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Refund policy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Cancellation refunds by timing', style: t.textTheme.titleLarge),
          const SizedBox(height: 12),
          const _PolicyBand(
            color: AppColors.success,
            window: 'More than 24 hours before departure',
            outcome: 'Full refund minus a flat ₹200 deduction',
          ),
          const _PolicyBand(
            color: AppColors.warning,
            window: '12–24 hours before departure',
            outcome: '50% of the fare is refunded',
          ),
          const _PolicyBand(
            color: AppColors.danger,
            window: 'Less than 12 hours before departure',
            outcome: 'No refund (100% deduction)',
          ),
          const SizedBox(height: 8),
          const _InfoBlock(
            title: 'Unpaid bookings',
            body:
                'Bookings that haven\'t been paid can be cancelled anytime at '
                'no charge — your held seat is simply released.',
          ),
          const _InfoBlock(
            title: 'Processing time',
            body:
                'Approved refunds are processed to your original payment method. '
                'You\'ll see the refund reference (e.g. RF1234) in your '
                'cancellation confirmation; bank settlement typically takes '
                '5–7 working days.',
          ),
        ],
      ),
    );
  }
}

class _PolicyBand extends StatelessWidget {
  const _PolicyBand(
      {required this.color, required this.window, required this.outcome});
  final Color color;
  final String window;
  final String outcome;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 46,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(3)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(window, style: t.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(outcome,
                      style: t.textTheme.bodySmall?.copyWith(
                          color: t.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
