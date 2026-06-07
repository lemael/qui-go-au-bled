import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/star_rating_widget.dart';
import '../review_provider.dart';

class ReviewsScreen extends ConsumerWidget {
  final String transporterId;
  const ReviewsScreen({super.key, required this.transporterId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync =
        ref.watch(transporterReviewsProvider(transporterId));

    return Scaffold(
      appBar: AppBar(title: const Text('Avis & Commentaires')),
      body: reviewsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorDisplayWidget(message: e.toString()),
        data: (reviews) {
          if (reviews.isEmpty) {
            return const EmptyStateWidget(
              title: 'Aucun avis',
              subtitle: 'Ce transporteur n\'a pas encore reçu d\'avis.',
              icon: Icons.reviews_outlined,
            );
          }

          final avgRating =
              reviews.map((r) => r.rating).reduce((a, b) => a + b) /
                  reviews.length;

          return Column(
            children: [
              _RatingSummary(
                averageRating: avgRating,
                totalReviews: reviews.length,
                reviews: reviews,
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reviews.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) =>
                      _ReviewCard(review: reviews[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RatingSummary extends StatelessWidget {
  final double averageRating;
  final int totalReviews;
  final List<ReviewEntity> reviews;

  const _RatingSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    final ratingCounts = List.generate(5, (i) {
      final star = 5 - i;
      return reviews.where((r) => r.rating.round() == star).length;
    });

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
              ),
              StarRatingWidget(rating: averageRating),
              const SizedBox(height: 4),
              Text(
                '$totalReviews avis',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.grey500),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              children: List.generate(5, (i) {
                final star = 5 - i;
                final count = ratingCounts[i];
                final pct = totalReviews > 0 ? count / totalReviews : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text(
                        '$star',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Icon(
                        Icons.star_rounded,
                        size: 12,
                        color: AppColors.starActive,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            minHeight: 6,
                            backgroundColor: AppColors.grey200,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.starActive,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final ReviewEntity review;
  const _ReviewCard({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    review.clientName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.clientName,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        DateFormatter.relativeTime(review.createdAt),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: AppColors.grey500),
                      ),
                    ],
                  ),
                ),
                StarRatingWidget(
                  rating: review.rating,
                  size: 16,
                  showLabel: true,
                ),
              ],
            ),
            if (review.comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(review.comment),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _CriteriaChip(label: 'Ponctualité', value: review.punctuality),
                _CriteriaChip(label: 'Communication', value: review.communication),
                _CriteriaChip(label: 'Colis', value: review.packageCondition),
                _CriteriaChip(label: 'Fiabilité', value: review.reliability),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CriteriaChip extends StatelessWidget {
  final String label;
  final double value;
  const _CriteriaChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.grey600),
          ),
          const SizedBox(width: 4),
          Icon(Icons.star_rounded, size: 12, color: AppColors.starActive),
          Text(
            value.toStringAsFixed(1),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
