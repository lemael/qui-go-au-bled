import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/providers/auth_provider.dart';

enum NotificationType {
  newRequest,
  requestAccepted,
  requestRejected,
  serviceStarted,
  serviceCompleted,
  newReview,
  orderCancelled,
}

class AppNotificationEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotificationEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    this.isRead = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, userId, isRead];
}

class AppNotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;

  const AppNotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotificationModel.fromJson(Map<String, dynamic> d) {
    return AppNotificationModel(
      id: d['id'] as String,
      userId: d['userId'] as String,
      title: d['title'] as String,
      body: d['body'] as String,
      type: d['type'] as String,
      relatedId: d['relatedId'] as String?,
      isRead: d['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(d['createdAt'] as String),
    );
  }

  AppNotificationEntity toEntity() => AppNotificationEntity(
        id: id,
        userId: userId,
        title: title,
        body: body,
        type: _typeFromString(type),
        relatedId: relatedId,
        isRead: isRead,
        createdAt: createdAt,
      );

  static NotificationType _typeFromString(String s) {
    switch (s) {
      case 'newRequest':       return NotificationType.newRequest;
      case 'requestAccepted':  return NotificationType.requestAccepted;
      case 'requestRejected':  return NotificationType.requestRejected;
      case 'serviceStarted':   return NotificationType.serviceStarted;
      case 'serviceCompleted': return NotificationType.serviceCompleted;
      case 'newReview':        return NotificationType.newReview;
      default:                 return NotificationType.orderCancelled;
    }
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final myNotificationsProvider = FutureProvider.autoDispose<List<AppNotificationEntity>>((ref) async {
  final user = ref.watch(currentUserNotifierProvider).value;
  if (user == null) return [];
  try {
    final response = await ApiClient.instance.dio.get('/notifications');
    return (response.data['notifications'] as List)
        .map((e) => AppNotificationModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  } catch (_) {
    return [];
  }
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(myNotificationsProvider);
  return notificationsAsync.maybeWhen(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  NotificationNotifier() : super(const AsyncData(null));

  Dio get _dio => ApiClient.instance.dio;

  Future<void> markAsRead(String notificationId) async {
    try {
      await _dio.patch('/notifications/$notificationId/read');
    } catch (_) {}
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _dio.patch('/notifications/read-all');
    } catch (_) {}
  }
}

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>(
  (ref) => NotificationNotifier(),
);
