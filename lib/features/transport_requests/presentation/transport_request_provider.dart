import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/providers/auth_provider.dart';
import '../domain/entities/transport_request_entity.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class TransportRequestModel {
  final String id;
  final String adId;
  final String transporterId;
  final String transporterName;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final String? message;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransportRequestModel({
    required this.id,
    required this.adId,
    required this.transporterId,
    required this.transporterName,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl,
    this.message,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransportRequestModel.fromJson(Map<String, dynamic> d) {
    return TransportRequestModel(
      id: d['id'] as String,
      adId: d['adId'] as String,
      transporterId: d['transporterId'] as String,
      transporterName: d['transporterName'] as String,
      clientId: d['clientId'] as String,
      clientName: d['clientName'] as String,
      clientPhotoUrl: d['clientPhotoUrl'] as String?,
      message: d['message'] as String?,
      status: d['status'] as String? ?? 'PENDING',
      createdAt: DateTime.parse(d['createdAt'] as String),
      updatedAt: DateTime.parse(d['updatedAt'] as String),
    );
  }

  TransportRequestEntity toEntity() => TransportRequestEntity(
        id: id,
        adId: adId,
        transporterId: transporterId,
        transporterName: transporterName,
        clientId: clientId,
        clientName: clientName,
        clientPhotoUrl: clientPhotoUrl,
        message: message,
        status: status == 'ACCEPTED'
            ? RequestStatus.accepted
            : status == 'REJECTED'
                ? RequestStatus.rejected
                : RequestStatus.pending,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

// ─── Providers ───────────────────────────────────────────────────────────────

final myClientRequestsProvider = FutureProvider.autoDispose<List<TransportRequestEntity>>((ref) async {
  final user = ref.watch(currentUserNotifierProvider).value;
  if (user == null) return [];
  try {
    final response = await ApiClient.instance.dio.get('/requests/as-client');
    return (response.data['requests'] as List)
        .map((e) => TransportRequestModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  } catch (_) {
    return [];
  }
});

final incomingRequestsProvider = FutureProvider.autoDispose<List<TransportRequestEntity>>((ref) async {
  final user = ref.watch(currentUserNotifierProvider).value;
  if (user == null) return [];
  try {
    final response = await ApiClient.instance.dio.get('/requests/incoming');
    return (response.data['requests'] as List)
        .map((e) => TransportRequestModel.fromJson(e as Map<String, dynamic>).toEntity())
        .toList();
  } catch (_) {
    return [];
  }
});

class RequestNotifier extends StateNotifier<AsyncValue<void>> {
  RequestNotifier() : super(const AsyncData(null));

  Dio get _dio => ApiClient.instance.dio;

  Future<bool> sendRequest({
    required String adId,
    required String transporterId,
    required String transporterName,
    required String clientId,
    required String clientName,
    String? clientPhotoUrl,
    String? message,
  }) async {
    state = const AsyncLoading();
    try {
      await _dio.post('/requests', data: {
        'adId': adId,
        'transporterId': transporterId,
        'transporterName': transporterName,
        'message': message,
      });
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(ApiClient.errorMessage(e), StackTrace.current);
      return false;
    }
  }

  Future<bool> acceptRequest(String requestId) => _updateStatus(requestId, 'accept');
  Future<bool> rejectRequest(String requestId) => _updateStatus(requestId, 'reject');

  Future<bool> _updateStatus(String requestId, String action) async {
    state = const AsyncLoading();
    try {
      await _dio.patch('/requests/$requestId/$action');
      state = const AsyncData(null);
      return true;
    } catch (e) {
      state = AsyncError(ApiClient.errorMessage(e), StackTrace.current);
      return false;
    }
  }
}

final requestNotifierProvider =
    StateNotifierProvider<RequestNotifier, AsyncValue<void>>(
  (ref) => RequestNotifier(),
);
