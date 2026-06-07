import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/transport_ad_entity.dart';
import '../../domain/repositories/transport_ad_repository.dart';
import '../models/transport_ad_model.dart';

class TransportAdRepositoryImpl implements TransportAdRepository {
  final Dio _dio;

  TransportAdRepositoryImpl(this._dio);

  @override
  Future<Either<Failure, TransportAdEntity>> createAd(TransportAdEntity ad) async {
    try {
      final response = await _dio.post('/ads', data: {
        'departureCity': ad.departureCity,
        'arrivalCity': ad.arrivalCity,
        'flightDate': ad.flightDate.toIso8601String().split('T')[0],
        'flightTime': ad.flightTime,
        'maxWeightKg': ad.maxWeightKg,
        'pricePerKg': ad.pricePerKg,
        'description': ad.description,
      });
      return Right(TransportAdModel.fromJson(response.data['ad'] as Map<String, dynamic>).toEntity());
    } catch (e) {
      return Left(ServerFailure(ApiClient.errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, TransportAdEntity>> updateAd(TransportAdEntity ad) async {
    try {
      final response = await _dio.put('/ads/${ad.id}', data: {
        'departureCity': ad.departureCity,
        'arrivalCity': ad.arrivalCity,
        'flightDate': ad.flightDate.toIso8601String().split('T')[0],
        'flightTime': ad.flightTime,
        'maxWeightKg': ad.maxWeightKg,
        'pricePerKg': ad.pricePerKg,
        'description': ad.description,
        'status': ad.status.name,
      });
      return Right(TransportAdModel.fromJson(response.data['ad'] as Map<String, dynamic>).toEntity());
    } catch (e) {
      return Left(ServerFailure(ApiClient.errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAd(String adId) async {
    try {
      await _dio.delete('/ads/$adId');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ApiClient.errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, TransportAdEntity>> getAdById(String adId) async {
    try {
      final response = await _dio.get('/ads/$adId');
      return Right(TransportAdModel.fromJson(response.data['ad'] as Map<String, dynamic>).toEntity());
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return const Left(NotFoundFailure('Annonce introuvable'));
      return Left(ServerFailure(ApiClient.errorMessage(e)));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TransportAdEntity>>> getActiveAds({
    String? departureCity,
    String? arrivalCity,
    DateTime? flightDate,
    int limit = 20,
    String? lastDocId,
  }) async {
    try {
      final response = await _dio.get('/ads', queryParameters: {
        if (departureCity != null && departureCity.isNotEmpty) 'departureCity': departureCity,
        if (arrivalCity != null && arrivalCity.isNotEmpty) 'arrivalCity': arrivalCity,
        if (flightDate != null) 'flightDate': flightDate.toIso8601String().split('T')[0],
        'limit': limit,
      });
      final ads = (response.data['ads'] as List)
          .map((e) => TransportAdModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();
      return Right(ads);
    } catch (e) {
      return Left(ServerFailure(ApiClient.errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, List<TransportAdEntity>>> getAdsByTransporter(String transporterId) async {
    try {
      final response = await _dio.get('/ads/my');
      final ads = (response.data['ads'] as List)
          .map((e) => TransportAdModel.fromJson(e as Map<String, dynamic>).toEntity())
          .toList();
      return Right(ads);
    } catch (e) {
      return Left(ServerFailure(ApiClient.errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, TransportAdEntity?>> getActiveAdByTransporter(String transporterId) async {
    try {
      final response = await _dio.get('/ads/my/active');
      final adData = response.data['ad'];
      if (adData == null) return const Right(null);
      return Right(TransportAdModel.fromJson(adData as Map<String, dynamic>).toEntity());
    } catch (e) {
      return Left(ServerFailure(ApiClient.errorMessage(e)));
    }
  }

  @override
  Future<Either<Failure, void>> deactivateAd(String adId) async {
    try {
      await _dio.patch('/ads/$adId/deactivate');
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(ApiClient.errorMessage(e)));
    }
  }

  @override
  Stream<List<TransportAdEntity>> watchActiveAds() {
    return Stream.fromFuture(
      getActiveAds().then((result) => result.fold((_) => <TransportAdEntity>[], (ads) => ads)),
    );
  }
}
