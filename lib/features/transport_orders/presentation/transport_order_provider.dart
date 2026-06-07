import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../domain/entities/transport_order_entity.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class TransportOrderModel {
  final String id;
  final String orderNumber;
  final String adId;
  final String requestId;
  final String transporterId;
  final String transporterName;
  final String? transporterPhotoUrl;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final String departureCity;
  final String arrivalCity;
  final DateTime flightDate;
  final double pricePerKg;
  final String status;
  final bool reviewAuthorized;
  final Map<String, dynamic>? cancellationInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransportOrderModel({
    required this.id,
    required this.orderNumber,
    required this.adId,
    required this.requestId,
    required this.transporterId,
    required this.transporterName,
    this.transporterPhotoUrl,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl,
    required this.departureCity,
    required this.arrivalCity,
    required this.flightDate,
    required this.pricePerKg,
    required this.status,
    required this.reviewAuthorized,
    this.cancellationInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransportOrderModel.fromJson(Map<String, dynamic> d) {
    return TransportOrderModel(
      id: d['id'] as String,
      orderNumber: d['orderNumber'] as String,
      adId: d['adId'] as String,
      requestId: d['requestId'] as String,
      transporterId: d['transporterId'] as String,
      transporterName: d['transporterName'] as String,
      transporterPhotoUrl: d['transporterPhotoUrl'] as String?,
      clientId: d['clientId'] as String,
      clientName: d['clientName'] as String,
      clientPhotoUrl: d['clientPhotoUrl'] as String?,
      departureCity: d['departureCity'] as String,
      arrivalCity: d['arrivalCity'] as String,
      flightDate: DateTime.parse(d['flightDate'] as String),
      pricePerKg: (d['pricePerKg'] as num).toDouble(),
      status: d['status'] as String? ?? 'ACCEPTED',
      reviewAuthorized: d['reviewAuthorized'] as bool? ?? false,
      cancellationInfo: d['cancellationInfo'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(d['createdAt'] as String),
      updatedAt: DateTime.parse(d['updatedAt'] as String),
    );
  }

  TransportOrderEntity toEntity() => TransportOrderEntity(
        id: id,
        orderNumber: orderNumber,
        adId: adId,
        requestId: requestId,
        transporterId: transporterId,
        transporterName: transporterName,
        transporterPhotoUrl: transporterPhotoUrl,
        clientId: clientId,
        clientName: clientName,
        clientPhotoUrl: clientPhotoUrl,
        departureCity: departureCity,
        arrivalCity: arrivalCity,
        flightDate: flightDate,
        pricePerKg: pricePerKg,
        status: _statusFromString(status),
        reviewAuthorized: reviewAuthorized,
        cancellationInfo: cancellationInfo != null
            ? CancellationInfo(
                authorId: cancellationInfo!['authorId'] as String,
                authorName: cancellationInfo!['authorName'] as String,
                reason: cancellationInfo!['reason'] as String,
                cancelledAt: DateTime.parse(cancellationInfo!['cancelledAt'] as String),
              )
            : null,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static OrderStatus _statusFromString(String s) {
    switch (s) {
      case 'PENDING':     return OrderStatus.pending;
      case 'ACCEPTED':    return OrderStatus.accepted;
      case 'REJECTED':    return OrderStatus.rejected;
      case 'IN_PROGRESS': return OrderStatus.inProgress;
      case 'COMPLETED':   return OrderStatus.completed;
      case 'CANCELLED':   return OrderStatus.cancelled;
      default:            return OrderStatus.pending;
    }
  }
}

// ─── Providers ───────────────────────────────────────────────────────────────

final myOrdersProvider = FutureProvider.autoDispose<List<TransportOrderEntity>>((ref) async {
  final user = ref.watch(currentUserNotifierProvider).value;
  if (user == null) return [];
  try {
    final response = await ApiClient.instance.dio.get('/orders');
    return (response.data['orders'] as List)
        .map((e) => TransportOrderModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  } catch (_) {
    return [];
  }
});

class OrderNotifier extends StateNotifier<AsyncValue<TransportOrderEntity?>> {
  final Ref _ref;
  OrderNotifier(this._ref) : super(const AsyncData(null));

  Dio get _dio => ApiClient.instance.dio;

  Future<String?> createOrder({
    required String adId,
    required String requestId,
    required String transporterId,
    required String transporterName,
    String? transporterPhotoUrl,
    required String clientId,
    required String clientName,
    String? clientPhotoUrl,
    required String departureCity,
    required String arrivalCity,
    required DateTime flightDate,
    required double pricePerKg,
  }) async {
    state = const AsyncLoading();
    try {
      final response = await _dio.post('/orders', data: {
        'adId': adId,
        'requestId': requestId,
        'transporterId': transporterId,
        'clientId': clientId,
        'departureCity': departureCity,
        'arrivalCity': arrivalCity,
        'flightDate': flightDate.toIso8601String().split('T')[0],
        'pricePerKg': pricePerKg,
      });
      final order = TransportOrderModel.fromJson(response.data['order'] as Map<String, dynamic>).toEntity();
      state = AsyncData(order);
      return response.data['orderNumber'] as String?;
    } catch (e) {
      state = AsyncError(ApiClient.errorMessage(e), StackTrace.current);
      return null;
    }
  }

  Future<bool> startService(String orderId) => _updateStatus(orderId, 'start');

  Future<bool> completeService(String orderId) => _updateStatus(orderId, 'complete');

  Future<bool> cancelOrder({
    required String orderId,
    required String authorId,
    required String authorName,
    required String reason,
  }) async {
    state = const AsyncLoading();
    try {
      await _dio.post('/orders/$orderId/cancel', data: {'reason': reason});
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(ApiClient.errorMessage(e), StackTrace.current);
      return false;
    }
  }

  Future<bool> _updateStatus(String orderId, String action) async {
    state = const AsyncLoading();
    try {
      await _dio.patch('/orders/$orderId/$action');
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(ApiClient.errorMessage(e), StackTrace.current);
      return false;
    }
  }
}

final orderNotifierProvider =
    StateNotifierProvider<OrderNotifier, AsyncValue<TransportOrderEntity?>>(
  (ref) => OrderNotifier(ref),
);
