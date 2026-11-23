import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/app.dart';
import 'app/di.dart';
import 'core/config/supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'es_PE';
  await initializeDateFormatting('es_PE');

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
