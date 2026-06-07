import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/star_rating_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../transport_orders/presentation/transport_order_provider.dart';
import '../review_provider.dart';

class CreateReviewScreen extends ConsumerStatefulWidget {
  final String orderId;
  const CreateReviewScreen({super.key, required this.orderId});

  @override
  ConsumerState<CreateReviewScreen> createState() =>
      _CreateReviewScreenState();
}

class _CreateReviewScreenState extends ConsumerState<CreateReviewScreen> {
  double _rating = 0;
  double _punctuality = 0;
  double _communication = 0;
  double _packageCondition = 0;
  double _reliability = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez donner une note globale'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final user = ref.read(currentUserNotifierProvider).value;
    final orders = ref.read(myOrdersProvider).value ?? [];
    final order = orders.where((o) => o.id == widget.orderId).firstOrNull;

    if (user == null || order == null) return;

    final success = await ref.read(reviewNotifierProvider.notifier).submitReview(
          orderId: widget.orderId,
          orderNumber: order.orderNumber,
          transporterId: order.transporterId,
          transporterName: order.transporterName,
          clientId: user.id,
          clientName: user.fullName,
          clientPhotoUrl: user.photoUrl,
          rating: _rating,
          comment: _commentController.text.trim(),
          punctuality: _punctuality > 0 ? _punctuality : _rating,
          communication: _communication > 0 ? _communication : _rating,
          packageCondition:
              _packageCondition > 0 ? _packageCondition : _rating,
          reliability: _reliability > 0 ? _reliability : _rating,
        );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Avis publié avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } else {
      final error = ref.read(reviewNotifierProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Erreur'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(reviewNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Laisser un avis')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Text(
                    'Note globale',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  InteractiveStarRating(
                    initialRating: _rating,
                    onRatingChanged: (r) => setState(() => _rating = r),
                    size: 44,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _rating == 0
                        ? 'Sélectionnez une note'
                        : _ratingLabel(_rating),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: AppColors.grey500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Critères détaillés',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _CriteriaRow(
              label: 'Ponctualité',
              icon: Icons.access_time_rounded,
              rating: _punctuality,
              onChanged: (v) => setState(() => _punctuality = v),
            ),
            _CriteriaRow(
              label: 'Communication',
              icon: Icons.chat_bubble_outline_rounded,
              rating: _communication,
              onChanged: (v) => setState(() => _communication = v),
            ),
            _CriteriaRow(
              label: 'État du colis',
              icon: Icons.inventory_2_outlined,
              rating: _packageCondition,
              onChanged: (v) => setState(() => _packageCondition = v),
            ),
            _CriteriaRow(
              label: 'Fiabilité',
              icon: Icons.verified_outlined,
              rating: _reliability,
              onChanged: (v) => setState(() => _reliability = v),
            ),
            const SizedBox(height: 24),
            Text(
              'Commentaire',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: const InputDecoration(
                hintText:
                    'Partagez votre expérience avec ce transporteur...',
              ),
            ),
            const SizedBox(height: 32),
            AppButtonFull(
              label: 'Publier l\'avis',
              onPressed: _submitReview,
              isLoading: isLoading,
              icon: Icons.publish_rounded,
            ),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(double rating) {
    if (rating >= 5) return 'Excellent !';
    if (rating >= 4) return 'Très bien';
    if (rating >= 3) return 'Bien';
    if (rating >= 2) return 'Passable';
    return 'Mauvais';
  }
}

class _CriteriaRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final double rating;
  final void Function(double) onChanged;

  const _CriteriaRow({
    required this.label,
    required this.icon,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: InteractiveStarRating(
              initialRating: rating,
              onRatingChanged: onChanged,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
