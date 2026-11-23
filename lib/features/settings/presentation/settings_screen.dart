import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/di.dart';
import '../../../app/theme.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/domain/auth_failure.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.extension<FinanceColors>()!;
    final authConfigured = ref.watch(authConfiguredProvider);
    final user = ref.watch(authSessionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE2F0E9), Color(0xFFF0F5E8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.lock_outline_rounded, color: colors.income),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tus datos son privados',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Los movimientos se guardan solo en este dispositivo. '
                        'La cuenta sirve para identificarte, no para '
                        'sincronizar.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          _SettingsLabel(label: 'ORGANIZACIÓN'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              ListTile(
                leading: const _LeadingIcon(icon: Icons.category_outlined),
                title: const Text('Categorías'),
                subtitle: const Text(
                  'Crea o elimina categorías de gastos e ingresos',
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () => context.push('/categorias'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SettingsLabel(label: 'PREFERENCIAS'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              ListTile(
                leading: const _LeadingIcon(icon: Icons.payments_outlined),
                title: const Text('Moneda'),
                subtitle: const Text('Sol peruano (PEN)'),
                trailing: Text(
                  'S/',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const Divider(height: 1, indent: 58),
              ListTile(
                leading: const _LeadingIcon(icon: Icons.file_download_outlined),
                title: const Text('Exportar historial'),
                subtitle: const Text(
                  'Hazlo desde Movimientos, con los filtros que elijas',
                ),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () => context.go('/movimientos'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SettingsLabel(label: 'CUENTA'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              if (!authConfigured)
                ListTile(
                  leading: const _LeadingIcon(
                    icon: Icons.person_outline_rounded,
                  ),
                  title: const Text('Inicio de sesión'),
                  subtitle: const Text(
                    'No configurado en esta compilación. La app sigue '
                    'funcionando con tus datos locales.',
                  ),
                  trailing: _StatusBadge(label: 'Local'),
                )
              else if (user == null)
                ListTile(
                  leading: const _LeadingIcon(icon: Icons.login_rounded),
                  title: const Text('Iniciar sesión'),
                  subtitle: const Text('Usa tu correo y contraseña'),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                  onTap: () => context.push('/login'),
                )
              else ...[
                ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      user.initials,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  title: Text(user.displayName),
                  subtitle: Text(user.email ?? 'Cuenta de Moneva'),
                ),
                const Divider(height: 1, indent: 58),
                ListTile(
                  leading: const _LeadingIcon(icon: Icons.logout_rounded),
                  title: const Text('Cerrar sesión'),
                  subtitle: const Text(
                    'Tus movimientos permanecen en este teléfono',
                  ),
                  onTap: () => _signOut(context, ref),
                ),
              ],
              const Divider(height: 1, indent: 58),
              ListTile(
                leading: const _LeadingIcon(icon: Icons.cloud_off_outlined),
                title: const Text('Sincronización'),
                subtitle: const Text(
                  'Los movimientos no se sincronizan entre dispositivos.',
                ),
                trailing: _StatusBadge(label: 'Próximamente'),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SettingsLabel(label: 'INFORMACIÓN'),
          const SizedBox(height: 8),
          _SettingsCard(
            children: [
              ListTile(
                leading: const _LeadingIcon(icon: Icons.shield_outlined),
                title: const Text('Privacidad'),
                trailing: const Icon(Icons.chevron_right_rounded, size: 20),
                onTap: () => _showPrivacy(context),
              ),
              const Divider(height: 1, indent: 58),
              ListTile(
                leading: const _LeadingIcon(icon: Icons.info_outline_rounded),
                title: const Text('Acerca de Moneva'),
                trailing: Text(
                  '1.0.0',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () => _showAbout(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: const Text(
          'Podrás volver a entrar con tu correo y contraseña. Tus movimientos '
          'seguirán guardados en este dispositivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      await ref.read(authRepositoryProvider).signOut();
    } on AuthFailure catch (failure) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(failure.message)));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('No se pudo cerrar sesión. Inténtalo de nuevo.'),
            ),
          );
      }
    }
  }

  void _showPrivacy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacidad'),
        content: const Text(
          'Los movimientos, categorías y notas se guardan en una base SQLite '
          'local en tu dispositivo.\n\n'
          'La cuenta de Moneva se usa solo para autenticarte con Supabase. '
          'Iniciar o cerrar sesión no borra ni modifica tus movimientos, y '
          'estos no se envían ni se sincronizan con Supabase.\n\n'
          'Las exportaciones CSV se generan localmente y solo salen del '
          'dispositivo cuando tú eliges compartirlas o guardarlas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Moneva'),
        content: const Text(
          'Versión 1.0.0\n\n'
          'Una app personal para registrar ingresos y gastos en soles, '
          'entender tu semana y revisar tu historial sin conexión.\n\n'
          'La cuenta de Moneva usa Supabase Auth solo para iniciar sesión. '
          'Los movimientos permanecen en SQLite, en este dispositivo.\n\n'
          'Hecha con Flutter, Riverpod, go_router, Drift/SQLite y Supabase Auth.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsLabel extends StatelessWidget {
  const _SettingsLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: children),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, size: 19, color: theme.colorScheme.primary),
    );
  }
}
