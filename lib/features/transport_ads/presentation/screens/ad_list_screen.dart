import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../providers/transport_ad_provider.dart';
import '../widgets/ad_card_widget.dart';

class AdListScreen extends ConsumerWidget {
  const AdListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adsAsync = ref.watch(activeAdsStreamProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Toutes les annonces')),
      body: adsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorDisplayWidget(message: e.toString()),
        data: (ads) {
          if (ads.isEmpty) {
            return const EmptyStateWidget(
              title: 'Aucune annonce disponible',
              icon: Icons.flight_outlined,
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: ads.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => AdCardWidget(
              ad: ads[index],
              onTap: () {},
            ),
          );
        },
      ),
    );
  }
}
