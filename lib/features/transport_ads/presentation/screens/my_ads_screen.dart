import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../routing/routes.dart';
import '../../domain/entities/transport_ad_entity.dart';
import '../providers/transport_ad_provider.dart';
import '../widgets/ad_card_widget.dart';

// Onglets filtrés par statut
const _tabs = [
  (label: 'Toutes',      statuses: <AdStatus>[]),
  (label: 'En attente',  statuses: [AdStatus.pending]),
  (label: 'Actives',     statuses: [AdStatus.active]),
  (label: 'Inactives',   statuses: [AdStatus.inactive, AdStatus.expired]),
  (label: 'Rejetées',    statuses: [AdStatus.rejected]),
];

class MyAdsScreen extends ConsumerStatefulWidget {
  const MyAdsScreen({super.key});

  @override
  ConsumerState<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends ConsumerState<MyAdsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(myTransporterAdsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes annonces'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: adsAsync.maybeWhen(
            data: (all) => _tabs.map((t) {
              final count = t.statuses.isEmpty
                  ? all.length
                  : all.where((a) => t.statuses.contains(a.status)).length;
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.label),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
            orElse: () =>
                _tabs.map((t) => Tab(text: t.label)).toList(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createAd),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle annonce'),
      ),
      body: adsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorDisplayWidget(message: e.toString()),
        data: (allAds) => TabBarView(
          controller: _tabController,
          children: _tabs.map((t) {
            final filtered = t.statuses.isEmpty
                ? allAds
                : allAds
                    .where((a) => t.statuses.contains(a.status))
                    .toList();
            return _AdList(
              ads: filtered,
              emptyLabel: t.label,
              onRefresh: () async => ref.invalidate(myTransporterAdsProvider),
              onDeactivate: (ad) async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Désactiver l\'annonce'),
                    content: const Text(
                        'Êtes-vous sûr de vouloir désactiver cette annonce ?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler')),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Désactiver')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(manageAdNotifierProvider.notifier)
                      .deactivateAd(ad.id);
                  ref.invalidate(myTransporterAdsProvider);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _AdList extends StatelessWidget {
  final List<TransportAdEntity> ads;
  final String emptyLabel;
  final Future<void> Function() onRefresh;
  final Future<void> Function(TransportAdEntity) onDeactivate;

  const _AdList({
    required this.ads,
    required this.emptyLabel,
    required this.onRefresh,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    if (ads.isEmpty) {
      return EmptyStateWidget(
        title: 'Aucune annonce',
        subtitle: emptyLabel == 'Toutes'
            ? 'Publiez votre première annonce pour proposer vos services.'
            : 'Aucune annonce avec le statut "$emptyLabel".',
        icon: Icons.add_box_outlined,
      );
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        itemCount: ads.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final ad = ads[index];
          return AdCardWidget(
            ad: ad,
            onTap: () => context.push('/ads/${ad.id}'),
            trailing: ad.status == AdStatus.active
                ? PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'deactivate') await onDeactivate(ad);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'deactivate',
                        child: Row(
                          children: [
                            Icon(Icons.block_rounded, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Désactiver'),
                          ],
                        ),
                      ),
                    ],
                  )
                : null,
          );
        },
      ),
    );
  }
}
