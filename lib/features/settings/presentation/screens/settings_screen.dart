import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../routing/routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserNotifierProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SettingsSection(
            title: 'Mon compte',
            items: [
              _SettingsTile(
                icon: Icons.person_outline_rounded,
                label: 'Modifier le profil',
                onTap: () => context.push(AppRoutes.editProfile),
              ),
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                label: 'Changer le mot de passe',
                onTap: () => context.push(AppRoutes.resetPassword),
              ),
              _SettingsTile(
                icon: Icons.phone_outlined,
                label: 'Téléphone',
                subtitle: user?.phone ?? '',
                onTap: () => context.push(AppRoutes.editProfile),
              ),
            ],
          ),
          if (user?.isTransporter == true)
            _SettingsSection(
              title: 'Transporteur',
              items: [
                _SettingsTile(
                  icon: Icons.dashboard_outlined,
                  label: 'Tableau de bord',
                  onTap: () => context.push(AppRoutes.dashboard),
                ),
                _SettingsTile(
                  icon: Icons.list_alt_rounded,
                  label: 'Mes annonces',
                  onTap: () => context.push(AppRoutes.myAds),
                ),
              ],
            ),
          _SettingsSection(
            title: 'Notifications',
            items: [
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Préférences de notification',
                onTap: () {},
              ),
            ],
          ),
          _SettingsSection(
            title: 'À propos',
            items: [
              _SettingsTile(
                icon: Icons.info_outline_rounded,
                label: 'Version de l\'application',
                subtitle: '1.0.0',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.privacy_tip_outlined,
                label: 'Politique de confidentialité',
                onTap: () {},
              ),
              _SettingsTile(
                icon: Icons.description_outlined,
                label: 'Conditions d\'utilisation',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () async {
                await ref
                    .read(currentUserNotifierProvider.notifier)
                    .signOut();
                // Le GoRouter redirect gère automatiquement la
                // navigation vers /login quand user == null.
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Se déconnecter'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _SettingsSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.grey400,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey200),
          ),
          child: Column(
            children: items
                .asMap()
                .entries
                .map(
                  (entry) => Column(
                    children: [
                      entry.value,
                      if (entry.key < items.length - 1)
                        const Divider(height: 1, indent: 56),
                    ],
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: AppColors.primary),
      ),
      title: Text(label),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}
