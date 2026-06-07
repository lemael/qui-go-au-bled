import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../routing/routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../transport_order_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(myOrdersProvider);
    final user = ref.watch(currentUserNotifierProvider).value;
    final isLoading = ref.watch(orderNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Détail du transport')),
      body: ordersAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorDisplayWidget(message: e.toString()),
        data: (orders) {
          final order =
              orders.where((o) => o.id == orderId).firstOrNull;
          if (order == null) {
            return const Center(child: Text('Transport introuvable'));
          }

          final isTransporter = user?.id == order.transporterId;
          final orderStatus = OrderStatusExtension.fromString(
            order.status.name.toUpperCase(),
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order number
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.primaryLight],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'N° de transport',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(
                            ClipboardData(text: order.orderNumber),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Numéro copié'),
                            ),
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              order.orderNumber,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.copy_rounded,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      StatusBadge(status: orderStatus),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Details card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _OrderDetailRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Transporteur',
                          value: order.transporterName,
                        ),
                        const Divider(),
                        _OrderDetailRow(
                          icon: Icons.person_4_outlined,
                          label: 'Client',
                          value: order.clientName,
                        ),
                        const Divider(),
                        _OrderDetailRow(
                          icon: Icons.flight_takeoff_rounded,
                          label: 'Départ',
                          value: order.departureCity,
                        ),
                        const Divider(),
                        _OrderDetailRow(
                          icon: Icons.flight_land_rounded,
                          label: 'Arrivée',
                          value: order.arrivalCity,
                        ),
                        const Divider(),
                        _OrderDetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date du vol',
                          value: DateFormatter.formatDate(order.flightDate),
                        ),
                        const Divider(),
                        _OrderDetailRow(
                          icon: Icons.euro_rounded,
                          label: 'Prix/kg',
                          value: '${order.pricePerKg}€',
                        ),
                      ],
                    ),
                  ),
                ),
                if (order.cancellationInfo != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    color: AppColors.error.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: AppColors.error.withOpacity(0.3),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                                color: AppColors.error,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Annulation',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Motif: ${order.cancellationInfo!.reason}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Par: ${order.cancellationInfo!.authorName}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                // Action buttons for transporter
                if (isTransporter && order.status.name == 'accepted') ...[
                  AppButtonFull(
                    label: 'Commencer le service',
                    onPressed: isLoading
                        ? null
                        : () async {
                            await ref
                                .read(orderNotifierProvider.notifier)
                                .startService(order.id);
                            ref.invalidate(myOrdersProvider);
                          },
                    isLoading: isLoading,
                    backgroundColor: AppColors.inProgress,
                    icon: Icons.play_arrow_rounded,
                  ),
                  const SizedBox(height: 12),
                ],
                if (isTransporter && order.status.name == 'inProgress') ...[
                  AppButtonFull(
                    label: 'Service terminé',
                    onPressed: isLoading
                        ? null
                        : () async {
                            await ref
                                .read(orderNotifierProvider.notifier)
                                .completeService(order.id);
                            ref.invalidate(myOrdersProvider);
                          },
                    isLoading: isLoading,
                    backgroundColor: AppColors.success,
                    icon: Icons.check_circle_rounded,
                  ),
                  const SizedBox(height: 12),
                ],
                if (order.canLeaveReview && !isTransporter) ...[
                  AppButtonFull(
                    label: 'Laisser un avis',
                    onPressed: () =>
                        context.push('/review/create/${order.id}'),
                    icon: Icons.star_outline_rounded,
                  ),
                  const SizedBox(height: 12),
                ],
                if (order.isActive) ...[
                  AppButtonFull(
                    label: 'Annuler le transport',
                    onPressed: () =>
                        context.push('/my-transports/${order.id}/cancel'),
                    backgroundColor: AppColors.error,
                    icon: Icons.cancel_outlined,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _OrderDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _OrderDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.grey500),
                ),
                Text(
                  value,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
