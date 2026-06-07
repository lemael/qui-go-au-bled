import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/star_rating_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/transport_ad_entity.dart';
import '../providers/transport_ad_provider.dart';

class AdDetailScreen extends ConsumerWidget {
  final String adId;
  const AdDetailScreen({super.key, required this.adId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final adAsync = ref.watch(
      // inline provider for single ad
      StreamProvider.family<TransportAdEntity?, String>((ref, id) {
        return ref.watch(transportAdRepositoryProvider).watchActiveAds().map(
              (ads) {
                try {
                  return ads.firstWhere((a) => a.id == id);
                } catch (_) {
                  return null;
                }
              },
            );
      })(adId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Détail de l\'annonce'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {
              final ad = adAsync.value;
              if (ad == null) return;
              await Share.share(ad.shareText);
            },
          ),
        ],
      ),
      body: adAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (adObj) {
          if (adObj == null) return const Center(child: Text('Annonce introuvable'));
          final ad = adObj;
          // Using dynamic cast since we used Object?
          final user = ref.watch(currentUserNotifierProvider).value;
          return _AdDetailBody(adId: adId, userId: user?.id ?? '');
        },
      ),
    );
  }
}

// Use a cleaner approach
class _AdDetailBody extends ConsumerWidget {
  final String adId;
  final String userId;

  const _AdDetailBody({required this.adId, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the ad directly from repository
    final adFuture = ref.watch(
      FutureProvider.autoDispose((ref) =>
          ref.watch(transportAdRepositoryProvider).getAdById(adId)),
    );

    return adFuture.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(e.toString())),
      data: (result) {
        return result.fold(
          (failure) => Center(child: Text(failure.message)),
          (ad) => SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Transporter info card
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      backgroundImage: ad.transporterPhotoUrl != null
                          ? CachedNetworkImageProvider(ad.transporterPhotoUrl!)
                          : null,
                      child: ad.transporterPhotoUrl == null
                          ? Text(
                              ad.transporterName.initials,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      ad.transporterName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Row(
                      children: [
                        StarRatingWidget(rating: ad.transporterRating),
                        const SizedBox(width: 4),
                        Text('(${ad.transporterReviews} avis)'),
                      ],
                    ),
                    trailing: TextButton(
                      onPressed: () => context
                          .push('/transporter/${ad.transporterId}'),
                      child: const Text('Voir profil'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Route card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _RouteRow(
                          departure: ad.departureCity,
                          arrival: ad.arrivalCity,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                              color: AppColors.grey500,
                            ),
                            const SizedBox(width: 8),
                            Text(DateFormatter.formatDate(ad.flightDate)),
                            const SizedBox(width: 16),
                            const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: AppColors.grey500,
                            ),
                            const SizedBox(width: 8),
                            Text(ad.flightTime),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Pricing card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _StatItem(
                            icon: Icons.scale_outlined,
                            label: 'Poids max',
                            value: '${ad.maxWeightKg} kg',
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: AppColors.grey200,
                        ),
                        Expanded(
                          child: _StatItem(
                            icon: Icons.euro_rounded,
                            label: 'Prix / kg',
                            value: '${ad.pricePerKg} €',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (ad.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Description',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(ad.description),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Action buttons
                if (ad.transporterId != userId) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    onPressed: () =>
                        context.push('/my-requests?adId=${ad.id}'),
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Envoyer une demande'),
                  ),
                  const SizedBox(height: 12),
                ],
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                  ),
                  onPressed: () async {
                    final waUrl = Uri.parse(
                      '${AppConstants.whatsappScheme}${Uri.encodeComponent(ad.shareText)}',
                    );
                    if (await canLaunchUrl(waUrl)) await launchUrl(waUrl);
                  },
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('Partager sur WhatsApp'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RouteRow extends StatelessWidget {
  final String departure;
  final String arrival;
  const _RouteRow({required this.departure, required this.arrival});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              const Icon(Icons.flight_takeoff_rounded, color: AppColors.primary),
              const SizedBox(height: 4),
              Text(
                departure,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const Icon(Icons.arrow_forward_rounded, color: AppColors.grey400),
        Expanded(
          child: Column(
            children: [
              const Icon(Icons.flight_land_rounded, color: AppColors.secondary),
              const SizedBox(height: 4),
              Text(
                arrival,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: AppColors.grey500),
        ),
      ],
    );
  }
}
