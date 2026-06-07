import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/string_extensions.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/star_rating_widget.dart';
import '../../domain/entities/transport_ad_entity.dart';

class AdCardWidget extends StatelessWidget {
  final TransportAdEntity ad;
  final VoidCallback onTap;
  final Widget? trailing;

  const AdCardWidget({
    super.key,
    required this.ad,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
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
                              fontSize: 12,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ad.transporterName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        StarRatingWidget(
                          rating: ad.transporterRating,
                          size: 14,
                          showLabel: true,
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                  if (trailing == null)
                    _StatusChip(status: ad.status),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.flight_takeoff_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      ad.departureCity,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.grey400,
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          ad.arrivalCity,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.flight_land_rounded,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: AppColors.grey400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormatter.formatDate(ad.flightDate),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.grey500),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.scale_outlined,
                    size: 14,
                    color: AppColors.grey400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${ad.maxWeightKg} kg',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.grey500),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${ad.pricePerKg}€/kg',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final AdStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == AdStatus.active
        ? AppColors.success
        : status == AdStatus.pending
            ? Colors.orange
            : status == AdStatus.rejected
                ? Colors.red
                : AppColors.grey400;
    final label = status == AdStatus.active
        ? 'Actif'
        : status == AdStatus.pending
            ? 'En attente'
            : status == AdStatus.rejected
                ? 'Rejeté'
                : 'Inactif';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
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
