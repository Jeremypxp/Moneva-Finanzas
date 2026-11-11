import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<FinanceColors>()!;

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
                        'Se guardan solo en este dispositivo. No necesitas internet.',
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
              ListTile(
                leading: const _LeadingIcon(icon: Icons.cloud_sync_outlined),
                title: const Text('Sincronización'),
                subtitle: const Text(
                  'Se habilitará en una próxima fase. Ahora no hay inicio de sesión.',
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Próximamente',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
                title: const Text('Acerca de Finanzas'),
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

  void _showPrivacy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacidad'),
        content: const Text(
          'Los movimientos, categorías y notas se guardan en una base SQLite '
          'local en tu dispositivo. La app no envía información a servidores ni '
          'requiere internet. Las exportaciones CSV se generan localmente y solo '
          'salen del dispositivo cuando tú eliges compartirlas o guardarlas.\n\n'
          'En una fase futura, una sincronización opcional con Supabase podría '
          'requerir una cuenta. Nada se enviará sin una acción tuya.',
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
        title: const Text('Finanzas'),
        content: const Text(
          'Versión 1.0.0\n\n'
          'Una app personal para registrar ingresos y gastos en soles, '
          'entender tu semana y revisar tu historial sin conexión.\n\n'
          'Hecha con Flutter, Riverpod, go_router y Drift/SQLite.',
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
