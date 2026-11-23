import 'package:flutter/foundation.dart';

/// Maneja los deep links entrantes de verificación de correo de Supabase.
///
/// Cuando la app se abre mediante `moneva://auth-callback/`, este handler
/// expone el URI recibido para que la pantalla de verificación lo procese.
class AuthDeepLinkHandler extends ChangeNotifier {
  static final AuthDeepLinkHandler instance = AuthDeepLinkHandler._internal();
  factory AuthDeepLinkHandler() => instance;
  AuthDeepLinkHandler._internal();

  Uri? _lastLink;
  Uri? get lastLink => _lastLink;

  /// Indica si hay un enlace pendiente por procesar.
  bool get hasPendingLink => _lastLink != null;

  /// Registra un deep link entrante.
  void receiveLink(Uri uri) {
    _lastLink = uri;
    notifyListeners();
  }

  /// Limpia el enlace pendiente después de mostrar la pantalla de verificación.
  void clearPendingLink() {
    _lastLink = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _lastLink = null;
    super.dispose();
  }
}
