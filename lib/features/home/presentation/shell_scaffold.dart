import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// Bottom navigation shell: Home · Rides · Bookings · Community · Profile.
class ShellScaffold extends StatelessWidget {
  const ShellScaffold({super.key, required this.child});
  final Widget child;

  static const _tabs = [
    (path: '/', icon: Icons.home_outlined, active: Icons.home_rounded, label: 'Home'),
    (path: '/live-rides', icon: Icons.directions_car_outlined, active: Icons.directions_car_rounded, label: 'Rides'),
    (path: '/my-bookings', icon: Icons.confirmation_number_outlined, active: Icons.confirmation_number_rounded, label: 'Bookings'),
    (path: '/community', icon: Icons.groups_outlined, active: Icons.groups_rounded, label: 'Community'),
    (path: '/profile', icon: Icons.person_outline_rounded, active: Icons.person_rounded, label: 'Profile'),
  ];

  int _indexOf(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final i = _tabs.indexWhere((t) => t.path == loc);
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context) {
    final index = _indexOf(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) {
          if (i == index) return;
          HapticFeedback.selectionClick();
          context.go(_tabs[i].path);
        },
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.active),
              label: t.label,
            ),
        ],
      ),
    );
  }
}
