import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/widgets/star_rating_widget.dart';
import '../../../../routing/routes.dart';
import '../../../transport_ads/domain/entities/transport_ad_entity.dart';
import '../../../transport_ads/presentation/providers/transport_ad_provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _confirmingLogout = false;

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(currentUserNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push(AppRoutes.editProfile),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.settings),
          ),
        ],
      ),
      body: userState.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (user) {
          if (user == null) return const Center(child: CircularProgressIndicator());
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: user.photoUrl != null
                          ? CachedNetworkImageProvider(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null
                          ? Text(
                              user.fullName.initials,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Client',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Transporteur',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                if (user.isTransporter) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StarRatingWidget(
                        rating: user.averageRating,
                        showLabel: true,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${user.totalReviews} avis)',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.grey500),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 32),
                _InfoCard(
                  children: [
                    _InfoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user.email,
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Téléphone',
                      value: user.phone,
                    ),
                    const Divider(),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Adresse',
                      value: user.address,
                    ),
                  ],
                ),
                if (user.isTransporter) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => context.push(AppRoutes.dashboard),
                          icon: const Icon(Icons.dashboard_outlined),
                          label: const Text('Tableau de bord'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.push('/reviews/${user.id}'),
                          icon: const Icon(Icons.star_outline_rounded),
                          label: const Text('Mes avis'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _AdsHistory(userId: user.id),
                ],
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: () {
                    setState(() => _confirmingLogout = true);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Se déconnecter'),
                ),
                if (_confirmingLogout)
                  Card(
                    color: AppColors.error.withOpacity(0.08),
                    margin: const EdgeInsets.only(top: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Êtes-vous sûr de vouloir vous déconnecter ?',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() => _confirmingLogout = false);
                                },
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                ),
                                onPressed: () async {
                                  setState(() => _confirmingLogout = false);
                                  await ref
                                      .read(currentUserNotifierProvider.notifier)
                                      .signOut();
                                },
                                child: const Text('Se déconnecter'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.grey500),
              ),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Historique des annonces ──────────────────────────────────────────────────

class _AdsHistory extends ConsumerWidget {
  final String userId;
  const _AdsHistory({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(myTransporterAdsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Historique des annonces',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            adsAsync.maybeWhen(
              data: (ads) => Text(
                '${ads.length} annonce${ads.length > 1 ? 's' : ''}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.grey500),
              ),
              orElse: () => const SizedBox(),
            ),
          ],
        ),
        const SizedBox(height: 12),
        adsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Text(
            'Impossible de charger les annonces',
            style: TextStyle(color: AppColors.error),
          ),
          data: (ads) {
            if (ads.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.flight_outlined,
                            size: 40, color: AppColors.grey400),
                        const SizedBox(height: 8),
                        Text(
                          'Aucune annonce publiée',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppColors.grey500),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            return Card(
              child: Column(
                children: [
                  for (int i = 0; i < ads.length; i++) ...[
                    if (i > 0)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                    _AdHistoryTile(
                      ad: ads[i],
                      onTap: () => context.push('/ads/${ads[i].id}'),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _AdHistoryTile extends StatelessWidget {
  final TransportAdEntity ad;
  final VoidCallback onTap;

  const _AdHistoryTile({required this.ad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.flight_takeoff_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ad.departureCity,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(Icons.arrow_forward_rounded,
                            size: 14, color: AppColors.grey400),
                      ),
                      Text(
                        ad.arrivalCity,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined,
                          size: 12, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text(
                        '${ad.flightDate.day.toString().padLeft(2,'0')}/${ad.flightDate.month.toString().padLeft(2,'0')}/${ad.flightDate.year}',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.grey500),
                      ),
                      const SizedBox(width: 10),
                      Icon(Icons.scale_outlined,
                          size: 12, color: AppColors.grey400),
                      const SizedBox(width: 4),
                      Text(
                        '${ad.maxWeightKg.toStringAsFixed(0)} kg · ${ad.pricePerKg.toStringAsFixed(2)}€/kg',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.grey500),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _AdStatusBadge(status: ad.status),
          ],
        ),
      ),
    );
  }
}

class _AdStatusBadge extends StatelessWidget {
  final AdStatus status;
  const _AdStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      AdStatus.active   => ('Actif', AppColors.success),
      AdStatus.pending  => ('En attente', Colors.orange),
      AdStatus.rejected => ('Rejeté', AppColors.error),
      AdStatus.inactive => ('Inactif', AppColors.grey400),
      AdStatus.expired  => ('Expiré', AppColors.grey400),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
