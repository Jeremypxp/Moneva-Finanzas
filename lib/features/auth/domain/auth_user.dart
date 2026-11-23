/// Usuario autenticado, independiente del proveedor de identidad.
class AuthUser {
  const AuthUser({required this.id, this.email, this.firstName, this.lastName});

  final String id;
  final String? email;
  final String? firstName;
  final String? lastName;

  String get displayName {
    final parts = [
      if (firstName != null && firstName!.trim().isNotEmpty) firstName!.trim(),
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!.trim(),
    ];
    if (parts.isNotEmpty) {
      return parts.join(' ');
    }
    return email ?? 'Tu cuenta';
  }

  String get initials {
    final source = displayName.trim();
    if (source.isEmpty) {
      return 'M';
    }
    final words = source.split(RegExp(r'\s+'));
    final first = words.first.substring(0, 1);
    final second = words.length > 1 ? words.last.substring(0, 1) : '';
    return '$first$second'.toUpperCase();
  }
}
