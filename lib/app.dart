import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "core/config/app_config.dart";
import "core/router/app_router.dart";
import "core/theme/app_theme.dart";
import "core/theme/theme_provider.dart";

class ShayreCabsApp extends ConsumerWidget {
  const ShayreCabsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      // Respect user font scaling but keep layouts sane on extreme settings.
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final scale = mq.textScaler.clamp(
            minScaleFactor: 0.85, maxScaleFactor: 1.3);
        return MediaQuery(
          data: mq.copyWith(textScaler: scale),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
