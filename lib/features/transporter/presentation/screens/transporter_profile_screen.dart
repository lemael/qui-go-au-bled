import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/star_rating_widget.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transport_ads/presentation/providers/transport_ad_provider.dart';
import '../../../transport_ads/presentation/widgets/ad_card_widget.dart';

class TransporterProfileScreen extends ConsumerWidget {
  final String userId;
  const TransporterProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(
      FutureProvider.autoDispose(
        (ref) => ref.watch(authRepositoryProvider).getUserById(userId),
      ),
    );
    final adsAsync = ref.watch(
      FutureProvider.autoDispose(
        (ref) => ref
            .watch(transportAdRepositoryProvider)
            .getAdsByTransporter(userId),
      ),
    );

    return Scaffold(
      body: userAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorDisplayWidget(message: e.toString()),
        data: (result) => result.fold(
          (failure) => ErrorDisplayWidget(message: failure.message),
          (user) => CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: _TransporterHero(user: user),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.star_outline_rounded),
                    onPressed: () =>
                        context.push('/reviews/${user.id}'),
                    tooltip: 'Voir les avis',
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats row
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              label: 'Avis',
                              value: '${user.totalReviews}',
                              icon: Icons.reviews_outlined,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              label: 'Note',
                              value: user.averageRating.toStringAsFixed(1),
                              icon: Icons.star_rounded,
                              iconColor: AppColors.starActive,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Annonce active',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              adsAsync.when(
                loading: () => const SliverToBoxAdapter(
                  child: LoadingWidget(),
                ),
                error: (_, __) => const SliverToBoxAdapter(
                  child: SizedBox(),
                ),
                data: (result) {
                  final ads = result.fold((_) => [], (a) => a);
                  final activeAd =
                      ads.where((a) => a.isActive).firstOrNull;
                  final historyAds =
                      ads.where((a) => !a.isActive).toList();

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        if (activeAd != null) ...[
                          AdCardWidget(
                            ad: activeAd,
                            onTap: () =>
                                context.push('/ads/${activeAd.id}'),
                          ),
                        ] else
                          const Center(
                            child: Text('Aucune annonce active'),
                          ),
                        if (historyAds.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Text(
                            'Historique des annonces',
                            style:
                                Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          ...historyAds.map(
                            (ad) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AdCardWidget(
                                ad: ad,
                                onTap: () =>
                                    context.push('/ads/${ad.id}'),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 80),
                      ]),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransporterHero extends StatelessWidget {
  final UserEntity user;
  const _TransporterHero({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            CircleAvatar(
              radius: 44,
              backgroundColor: Colors.white.withOpacity(0.2),
              backgroundImage: user.photoUrl != null
                  ? CachedNetworkImageProvider(user.photoUrl!)
                  : null,
              child: user.photoUrl == null
                  ? Text(
                      user.fullName.initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            Text(
              user.fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            StarRatingWidget(
              rating: user.averageRating,
              size: 18,
              showLabel: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 28,
              color: iconColor ?? AppColors.primary,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                Text(
                  label,
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
    );
  }
}
