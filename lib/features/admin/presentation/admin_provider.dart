import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../auth/domain/entities/user_entity.dart';
import '../../auth/data/models/user_model.dart';
import '../../transport_ads/data/models/transport_ad_model.dart';
import '../../transport_ads/domain/entities/transport_ad_entity.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class AdminState {
  final List<UserEntity> users;
  final List<TransportAdEntity> pendingAds;
  final Map<String, int> stats;
  final bool isLoading;
  final String? error;

  const AdminState({
    this.users = const [],
    this.pendingAds = const [],
    this.stats = const {},
    this.isLoading = false,
    this.error,
  });

  AdminState copyWith({
    List<UserEntity>? users,
    List<TransportAdEntity>? pendingAds,
    Map<String, int>? stats,
    bool? isLoading,
    String? error,
  }) =>
      AdminState(
        users: users ?? this.users,
        pendingAds: pendingAds ?? this.pendingAds,
        stats: stats ?? this.stats,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(const AdminState());

  Future<void> loadStats() async {
    try {
      final resp = await ApiClient.instance.dio.get('/admin/stats');
      final data = resp.data as Map<String, dynamic>;
      state = state.copyWith(
        stats: {
          'totalUsers': data['totalUsers'] as int? ?? 0,
          'activeAds': data['activeAds'] as int? ?? 0,
          'pendingAds': data['pendingAds'] as int? ?? 0,
          'totalOrders': data['totalOrders'] as int? ?? 0,
        },
      );
    } catch (_) {}
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await ApiClient.instance.dio.get('/admin/users');
      final list = (resp.data['users'] as List)
          .map((e) => UserModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();
      state = state.copyWith(users: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadPendingAds() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await ApiClient.instance.dio.get('/admin/ads/pending');
      final list = (resp.data['ads'] as List)
          .map((e) => TransportAdModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();
      state = state.copyWith(pendingAds: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> approveAd(String adId) async {
    try {
      await ApiClient.instance.dio.patch('/admin/ads/$adId/approve');
      state = state.copyWith(
        pendingAds: state.pendingAds.where((a) => a.id != adId).toList(),
        stats: {
          ...state.stats,
          'pendingAds': (state.stats['pendingAds'] ?? 1) - 1,
          'activeAds': (state.stats['activeAds'] ?? 0) + 1,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> rejectAd(String adId, {String reason = ''}) async {
    try {
      await ApiClient.instance.dio.patch('/admin/ads/$adId/reject', data: {'reason': reason});
      state = state.copyWith(
        pendingAds: state.pendingAds.where((a) => a.id != adId).toList(),
        stats: {
          ...state.stats,
          'pendingAds': (state.stats['pendingAds'] ?? 1) - 1,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteUser(String userId) async {
    try {
      await ApiClient.instance.dio.delete('/admin/users/$userId');
      state = state.copyWith(
        users: state.users.where((u) => u.id != userId).toList(),
        stats: {
          ...state.stats,
          'totalUsers': (state.stats['totalUsers'] ?? 1) - 1,
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>(
  (ref) => AdminNotifier(),
);
