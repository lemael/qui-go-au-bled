import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

// ─── Entity ───────────────────────────────────────────────────────────────────

class ReviewEntity extends Equatable {
  final String id;
  final String orderId;
  final String orderNumber;
  final String transporterId;
  final String transporterName;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final double rating;
  final String comment;
  final double punctuality;
  final double communication;
  final double packageCondition;
  final double reliability;
  final DateTime createdAt;

  const ReviewEntity({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.transporterId,
    required this.transporterName,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl,
    required this.rating,
    required this.comment,
    required this.punctuality,
    required this.communication,
    required this.packageCondition,
    required this.reliability,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, orderId, clientId, transporterId];
}

// ─── Model ───────────────────────────────────────────────────────────────────

class ReviewModel {
  final String id;
  final String orderId;
  final String orderNumber;
  final String transporterId;
  final String transporterName;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final double rating;
  final String comment;
  final double punctuality;
  final double communication;
  final double packageCondition;
  final double reliability;
  final DateTime createdAt;

  const ReviewModel({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.transporterId,
    required this.transporterName,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl,
    required this.rating,
    required this.comment,
    required this.punctuality,
    required this.communication,
    required this.packageCondition,
    required this.reliability,
    required this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> d) {
    return ReviewModel(
      id: d['id'] as String,
      orderId: d['orderId'] as String,
      orderNumber: d['orderNumber'] as String,
      transporterId: d['transporterId'] as String,
      transporterName: d['transporterName'] as String? ?? '',
      clientId: d['clientId'] as String,
      clientName: d['clientName'] as String? ?? '',
      clientPhotoUrl: d['clientPhotoUrl'] as String?,
      rating: (d['rating'] as num).toDouble(),
      comment: d['comment'] as String? ?? '',
      punctuality: (d['punctuality'] as num?)?.toDouble() ?? 0,
      communication: (d['communication'] as num?)?.toDouble() ?? 0,
      packageCondition: (d['packageCondition'] as num?)?.toDouble() ?? 0,
      reliability: (d['reliability'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(d['createdAt'] as String),
    );
  }

  ReviewEntity toEntity() => ReviewEntity(
        id: id,
        orderId: orderId,
        orderNumber: orderNumber,
        transporterId: transporterId,
        transporterName: transporterName,
        clientId: clientId,
        clientName: clientName,
        clientPhotoUrl: clientPhotoUrl,
        rating: rating,
        comment: comment,
        punctuality: punctuality,
        communication: communication,
        packageCondition: packageCondition,
        reliability: reliability,
        createdAt: createdAt,
      );
}

// ─── Providers ───────────────────────────────────────────────────────────────

final transporterReviewsProvider = FutureProviderFamily<List<ReviewEntity>, String>(
  (ref, transporterId) async {
    try {
      final response = await ApiClient.instance.dio.get('/reviews/transporter/$transporterId');
      return (response.data['reviews'] as List)
          .map((e) => ReviewModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();
    } catch (_) {
      return [];
    }
  },
);

class ReviewNotifier extends StateNotifier<AsyncValue<void>> {
  ReviewNotifier() : super(const AsyncData(null));

  Dio get _dio => ApiClient.instance.dio;

  Future<bool> submitReview({
    required String orderId,
    required String orderNumber,
    required String transporterId,
    required String transporterName,
    required String clientId,
    required String clientName,
    String? clientPhotoUrl,
    required double rating,
    required String comment,
    required double punctuality,
    required double communication,
    required double packageCondition,
    required double reliability,
  }) async {
    state = const AsyncLoading();
    try {
      await _dio.post('/reviews', data: {
        'orderId': orderId,
        'orderNumber': orderNumber,
        'transporterId': transporterId,
        'transporterName': transporterName,
        'rating': rating,
        'comment': comment,
        'punctuality': punctuality,
        'communication': communication,
        'packageCondition': packageCondition,
        'reliability': reliability,
      });
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(ApiClient.errorMessage(e), StackTrace.current);
      return false;
    }
  }
}

final reviewNotifierProvider =
    StateNotifierProvider<ReviewNotifier, AsyncValue<void>>(
  (ref) => ReviewNotifier(),
);
