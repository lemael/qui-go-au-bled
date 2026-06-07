import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/transport_ad_entity.dart';

abstract class TransportAdRepository {
  Future<Either<Failure, TransportAdEntity>> createAd(
    TransportAdEntity ad,
  );

  Future<Either<Failure, TransportAdEntity>> updateAd(
    TransportAdEntity ad,
  );

  Future<Either<Failure, void>> deleteAd(String adId);

  Future<Either<Failure, TransportAdEntity>> getAdById(String adId);

  Future<Either<Failure, List<TransportAdEntity>>> getActiveAds({
    String? departureCity,
    String? arrivalCity,
    DateTime? flightDate,
    int limit = 20,
    String? lastDocId,
  });

  Future<Either<Failure, List<TransportAdEntity>>> getAdsByTransporter(
    String transporterId,
  );

  Future<Either<Failure, TransportAdEntity?>> getActiveAdByTransporter(
    String transporterId,
  );

  Future<Either<Failure, void>> deactivateAd(String adId);

  Stream<List<TransportAdEntity>> watchActiveAds();
}
