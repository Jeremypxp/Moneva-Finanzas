import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'core/config/supabase_config.dart';
import 'features/auth/application/auth_deep_link_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'es_PE';
  await initializeDateFormatting('es_PE');

  // Escucha los deep links de verificación de correo de Supabase.
  final appLinks = AppLinks();
  appLinks.uriLinkStream.listen((uri) {
    if (uri.scheme == 'moneva' && uri.host == 'auth-callback') {
      AuthDeepLinkHandler.instance.receiveLink(uri);
    }
  });

  var authReady = false;
  if (SupabaseConfig.hasCredentials) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.key,
      );
      authReady = true;
    } catch (_) {
      // No se registra el error para no exponer datos de configuración.
      debugPrint(
        'Supabase Auth no pudo inicializarse; se usará el modo local.',
      );
    }
  }

  runApp(
    ProviderScope(
      overrides: [authConfiguredProvider.overrideWithValue(authReady)],
      child: const MonevaApp(),
    ),
  );
}
