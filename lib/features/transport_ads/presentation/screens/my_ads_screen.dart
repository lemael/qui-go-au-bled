import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../routing/routes.dart';
import '../providers/transport_ad_provider.dart';
import '../widgets/ad_card_widget.dart';

class MyAdsScreen extends ConsumerWidget {
  const MyAdsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(myTransporterAdsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes annonces')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createAd),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nouvelle annonce'),
      ),
      body: adsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorDisplayWidget(message: e.toString()),
        data: (ads) {
          if (ads.isEmpty) {
            return const EmptyStateWidget(
              title: 'Aucune annonce',
              subtitle:
                  'Publiez votre première annonce pour proposer vos services.',
              icon: Icons.add_box_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(myTransporterAdsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: ads.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ad = ads[index];
                return AdCardWidget(
                  ad: ad,
                  onTap: () => context.push('/ads/${ad.id}'),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'deactivate') {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Désactiver l\'annonce'),
                            content: const Text(
                              'Êtes-vous sûr de vouloir désactiver cette annonce ?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Annuler'),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Désactiver'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await ref
                              .read(manageAdNotifierProvider.notifier)
                              .deactivateAd(ad.id);
                          ref.invalidate(myTransporterAdsProvider);
                        }
                      }
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
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
