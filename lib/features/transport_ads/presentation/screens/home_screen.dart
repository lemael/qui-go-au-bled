import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../routing/routes.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/transport_ad_provider.dart';
import '../widgets/ad_card_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserNotifierProvider).value;
    final adsAsync = ref.watch(activeAdsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bonjour, ${user?.fullName.split(' ').first ?? ''} 👋',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Trouvez un transporteur de confiance',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.grey500),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        ],
      ),
      floatingActionButton: user?.isTransporter == true
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.createAd),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Publier une annonce'),
            )
          : null,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(activeAdsStreamProvider),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _SearchBanner(
                onSearch: () => context.push(AppRoutes.search),
              ),
            ),
            if (user?.isTransporter == true)
              SliverToBoxAdapter(
                child: _TransporterQuickActions(user: user!),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Annonces récentes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            adsAsync.when(
              loading: () => const SliverFillRemaining(
                child: LoadingWidget(message: 'Chargement des annonces...'),
              ),
              error: (e, _) => SliverFillRemaining(
                child: ErrorDisplayWidget(message: e.toString()),
              ),
              data: (ads) {
                if (ads.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyStateWidget(
                      title: 'Aucune annonce disponible',
                      subtitle:
                          'Revenez bientôt pour trouver un transporteur.',
                      icon: Icons.flight_outlined,
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AdCardWidget(
                          ad: ads[index],
                          onTap: () =>
                              context.push('/ads/${ads[index].id}'),
                        ),
                      ),
                      childCount: ads.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBanner extends StatelessWidget {
  final VoidCallback onSearch;
  const _SearchBanner({required this.onSearch});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onSearch,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Où voulez-vous envoyer ?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Rechercher une destination...',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TransporterQuickActions extends StatelessWidget {
  final UserEntity user;
  const _TransporterQuickActions({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionCard(
              icon: Icons.add_box_outlined,
              label: 'Nouvelle annonce',
              color: AppColors.primary,
              onTap: () => context.push(AppRoutes.createAd),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.list_alt_rounded,
              label: 'Les annonces',
              color: AppColors.secondary,
              onTap: () => context.push(AppRoutes.myAds),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _QuickActionCard(
              icon: Icons.dashboard_outlined,
              label: 'Dashboard',
              color: AppColors.inProgress,
              onTap: () => context.push(AppRoutes.dashboard),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
