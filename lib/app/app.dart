import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'router.dart';
import 'theme.dart';

import '../features/auth/application/auth_providers.dart';

class MonevaApp extends ConsumerWidget {
  const MonevaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Navega a la pantalla de verificación cuando llega un deep link
    // de confirmación de correo (moneva://auth-callback/).
    ref.listen(authDeepLinkHandlerProvider, (previous, next) {
      if (next.hasPendingLink &&
          (previous == null || !previous.hasPendingLink)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) {
            return;
          }
          context.go('/auth-callback');
        });
      }
    });

    return MaterialApp.router(
      title: 'Moneva',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: ref.watch(appRouterProvider),
      locale: const Locale('es', 'PE'),
      supportedLocales: const [Locale('es', 'PE'), Locale('es')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
