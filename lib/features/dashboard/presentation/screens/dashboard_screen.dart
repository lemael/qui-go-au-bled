import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class DashboardStats {
  final int totalOrders;
  final int completedOrders;
  final int cancelledOrders;
  final double successRate;
  final double averageRating;
  final int totalReviews;

  const DashboardStats({
    required this.totalOrders,
    required this.completedOrders,
    required this.cancelledOrders,
    required this.successRate,
    required this.averageRating,
    required this.totalReviews,
  });
}

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((ref) async {
  final user = ref.watch(currentUserNotifierProvider).value;
  if (user == null) {
    return const DashboardStats(
      totalOrders: 0,
      completedOrders: 0,
      cancelledOrders: 0,
      successRate: 0,
      averageRating: 0,
      totalReviews: 0,
    );
  }

  try {
    final response = await ApiClient.instance.dio.get('/orders');
    final orders = response.data['orders'] as List;
    final total = orders.length;
    final completed = orders.where((d) => d['status'] == 'COMPLETED').length;
    final cancelled = orders.where((d) => d['status'] == 'CANCELLED').length;
    final rate = total > 0 ? (completed / total) * 100 : 0.0;

    return DashboardStats(
      totalOrders: total,
      completedOrders: completed,
      cancelledOrders: cancelled,
      successRate: rate,
      averageRating: user.averageRating,
      totalReviews: user.totalReviews,
    );
  } catch (_) {
    return DashboardStats(
      totalOrders: 0,
      completedOrders: 0,
      cancelledOrders: 0,
      successRate: 0,
      averageRating: user.averageRating,
      totalReviews: user.totalReviews,
    );
  }
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tableau de bord')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardStatsProvider),
        child: statsAsync.when(
          loading: () => const LoadingWidget(),
          error: (e, _) => ErrorDisplayWidget(message: e.toString()),
          data: (stats) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vos statistiques',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _StatCard(
                      title: 'Total transports',
                      value: '${stats.totalOrders}',
                      icon: Icons.local_shipping_rounded,
                      color: AppColors.primary,
                    ),
                    _StatCard(
                      title: 'Réussis',
                      value: '${stats.completedOrders}',
                      icon: Icons.task_alt_rounded,
                      color: AppColors.success,
                    ),
                    _StatCard(
                      title: 'Annulations',
                      value: '${stats.cancelledOrders}',
                      icon: Icons.block_rounded,
                      color: AppColors.error,
                    ),
                    _StatCard(
                      title: 'Taux réussite',
                      value: '${stats.successRate.toStringAsFixed(0)}%',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.inProgress,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Note moyenne',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Row(
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: AppColors.starActive,
                                  size: 20,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  stats.averageRating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Nombre d\'avis'),
                            Text(
                              '${stats.totalReviews} avis',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (stats.totalOrders > 0) ...[
                  Text(
                    'Performance',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  _ProgressBar(
                    label: 'Taux de réussite',
                    value: stats.successRate / 100,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 8),
                  _ProgressBar(
                    label: 'Taux d\'annulation',
                    value: stats.totalOrders > 0
                        ? stats.cancelledOrders / stats.totalOrders
                        : 0,
                    color: AppColors.error,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                ),
                Text(
                  title,
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

class _ProgressBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _ProgressBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: AppColors.grey100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
