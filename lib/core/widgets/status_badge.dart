import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum OrderStatus { pending, accepted, rejected, inProgress, completed, cancelled }

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'En attente';
      case OrderStatus.accepted:
        return 'Accepté';
      case OrderStatus.rejected:
        return 'Refusé';
      case OrderStatus.inProgress:
        return 'En cours';
      case OrderStatus.completed:
        return 'Terminé';
      case OrderStatus.cancelled:
        return 'Annulé';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return AppColors.pending;
      case OrderStatus.accepted:
        return AppColors.accepted;
      case OrderStatus.rejected:
        return AppColors.rejected;
      case OrderStatus.inProgress:
        return AppColors.inProgress;
      case OrderStatus.completed:
        return AppColors.completed;
      case OrderStatus.cancelled:
        return AppColors.cancelled;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:
        return Icons.hourglass_top_rounded;
      case OrderStatus.accepted:
        return Icons.check_circle_outline_rounded;
      case OrderStatus.rejected:
        return Icons.cancel_outlined;
      case OrderStatus.inProgress:
        return Icons.local_shipping_outlined;
      case OrderStatus.completed:
        return Icons.task_alt_rounded;
      case OrderStatus.cancelled:
        return Icons.block_rounded;
    }
  }

  static OrderStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.pending;
      case 'ACCEPTED':
        return OrderStatus.accepted;
      case 'REJECTED':
        return OrderStatus.rejected;
      case 'IN_PROGRESS':
        return OrderStatus.inProgress;
      case 'COMPLETED':
        return OrderStatus.completed;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  String get value {
    switch (this) {
      case OrderStatus.pending:
        return 'PENDING';
      case OrderStatus.accepted:
        return 'ACCEPTED';
      case OrderStatus.rejected:
        return 'REJECTED';
      case OrderStatus.inProgress:
        return 'IN_PROGRESS';
      case OrderStatus.completed:
        return 'COMPLETED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }
}

class StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}
