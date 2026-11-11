import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'router.dart';
import 'theme.dart';

class MonevaApp extends StatelessWidget {
  const MonevaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Moneva',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: appRouter,
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
