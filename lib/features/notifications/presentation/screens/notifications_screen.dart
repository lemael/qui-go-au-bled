import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/empty_state_widget.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../notification_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(myNotificationsProvider);
    final user = ref.watch(currentUserNotifierProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: user == null
                ? null
                : () => ref
                    .read(notificationNotifierProvider.notifier)
                    .markAllAsRead(user.id),
            child: const Text('Tout lire'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const LoadingWidget(),
        error: (e, _) => ErrorDisplayWidget(message: e.toString()),
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              title: 'Aucune notification',
              subtitle: 'Vous êtes à jour !',
              icon: Icons.notifications_none_rounded,
            );
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
            itemBuilder: (context, index) {
              final n = notifications[index];
              return _NotificationTile(
                notification: n,
                onTap: () {
                  if (!n.isRead) {
                    ref
                        .read(notificationNotifierProvider.notifier)
                        .markAsRead(n.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotificationEntity notification;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: notification.isRead ? null : AppColors.primary.withOpacity(0.04),
      leading: CircleAvatar(
        backgroundColor: _iconColor.withOpacity(0.1),
        child: Icon(_iconData, color: _iconColor, size: 20),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight:
              notification.isRead ? FontWeight.w400 : FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(notification.body, maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(
            DateFormatter.relativeTime(notification.createdAt),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.grey400,
            ),
          ),
        ],
      ),
      isThreeLine: true,
      trailing: notification.isRead
          ? null
          : Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
    );
  }

  IconData get _iconData {
    switch (notification.type) {
      case NotificationType.newRequest:
        return Icons.inbox_rounded;
      case NotificationType.requestAccepted:
        return Icons.check_circle_outline_rounded;
      case NotificationType.requestRejected:
        return Icons.cancel_outlined;
      case NotificationType.serviceStarted:
        return Icons.local_shipping_outlined;
      case NotificationType.serviceCompleted:
        return Icons.task_alt_rounded;
      case NotificationType.newReview:
        return Icons.star_outline_rounded;
      case NotificationType.orderCancelled:
        return Icons.block_rounded;
    }
  }

  Color get _iconColor {
    switch (notification.type) {
      case NotificationType.newRequest:
        return AppColors.info;
      case NotificationType.requestAccepted:
        return AppColors.success;
      case NotificationType.requestRejected:
        return AppColors.error;
      case NotificationType.serviceStarted:
        return AppColors.inProgress;
      case NotificationType.serviceCompleted:
        return AppColors.success;
      case NotificationType.newReview:
        return AppColors.starActive;
      case NotificationType.orderCancelled:
        return AppColors.error;
    }
  }
}
