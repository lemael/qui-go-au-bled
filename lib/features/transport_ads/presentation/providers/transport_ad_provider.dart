import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/repositories/transport_ad_repository_impl.dart';
import '../../domain/entities/transport_ad_entity.dart';
import '../../domain/repositories/transport_ad_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

final transportAdRepositoryProvider = Provider<TransportAdRepository>((ref) {
  return TransportAdRepositoryImpl(ApiClient.instance.dio);
});

final activeAdsStreamProvider = StreamProvider<List<TransportAdEntity>>((ref) {
  return ref.watch(transportAdRepositoryProvider).watchActiveAds();
});

// Search/filter ads
class AdSearchNotifier extends StateNotifier<AsyncValue<List<TransportAdEntity>>> {
  final Ref _ref;
  AdSearchNotifier(this._ref) : super(const AsyncData([]));

  Future<void> search({
    String? departureCity,
    String? arrivalCity,
    DateTime? flightDate,
  }) async {
    state = const AsyncLoading();
    final result = await _ref.read(transportAdRepositoryProvider).getActiveAds(
          departureCity: departureCity,
          arrivalCity: arrivalCity,
          flightDate: flightDate,
        );
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (ads) => AsyncData(ads),
    );
  }

  void reset() => state = const AsyncData([]);
}

final adSearchNotifierProvider =
    StateNotifierProvider<AdSearchNotifier, AsyncValue<List<TransportAdEntity>>>(
  (ref) => AdSearchNotifier(ref),
);

final myTransporterAdsProvider =
    FutureProvider.autoDispose<List<TransportAdEntity>>((ref) async {
  final user = ref.watch(currentUserNotifierProvider).value;
  if (user == null) return [];
  final result = await ref
      .read(transportAdRepositoryProvider)
      .getAdsByTransporter(user.id);
  return result.fold((_) => [], (ads) => ads);
});

final myActiveAdProvider =
    FutureProvider.autoDispose<TransportAdEntity?>((ref) async {
  final user = ref.watch(currentUserNotifierProvider).value;
  if (user == null) return null;
  final result = await ref
      .read(transportAdRepositoryProvider)
      .getActiveAdByTransporter(user.id);
  return result.fold((_) => null, (ad) => ad);
});

class ManageAdNotifier extends StateNotifier<AsyncValue<TransportAdEntity?>> {
  final Ref _ref;
  ManageAdNotifier(this._ref) : super(const AsyncData(null));

  Future<bool> createAd(TransportAdEntity ad) async {
    state = const AsyncLoading();
    final result = await _ref.read(transportAdRepositoryProvider).createAd(ad);
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (ad) => AsyncData(ad),
    );
    return result.isRight();
  }

  Future<bool> updateAd(TransportAdEntity ad) async {
    state = const AsyncLoading();
    final result = await _ref.read(transportAdRepositoryProvider).updateAd(ad);
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (ad) => AsyncData(ad),
    );
    return result.isRight();
  }

  Future<bool> deactivateAd(String adId) async {
    state = const AsyncLoading();
    final result =
        await _ref.read(transportAdRepositoryProvider).deactivateAd(adId);
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (_) => const AsyncData(null),
    );
    return result.isRight();
  }
}

final manageAdNotifierProvider = StateNotifierProvider<ManageAdNotifier,
    AsyncValue<TransportAdEntity?>>(
  (ref) => ManageAdNotifier(ref),
);
