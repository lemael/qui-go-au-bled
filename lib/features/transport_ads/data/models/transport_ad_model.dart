import '../../domain/entities/transport_ad_entity.dart';

class TransportAdModel {
  final String id;
  final String transporterId;
  final String transporterName;
  final String? transporterPhotoUrl;
  final double transporterRating;
  final int transporterReviews;
  final String departureCity;
  final String arrivalCity;
  final DateTime flightDate;
  final String flightTime;
  final double maxWeightKg;
  final double pricePerKg;
  final String description;
  final String status;
  final int totalPackagesCarried;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransportAdModel({
    required this.id,
    required this.transporterId,
    required this.transporterName,
    this.transporterPhotoUrl,
    this.transporterRating = 0.0,
    this.transporterReviews = 0,
    required this.departureCity,
    required this.arrivalCity,
    required this.flightDate,
    required this.flightTime,
    required this.maxWeightKg,
    required this.pricePerKg,
    required this.description,
    this.status = 'active',
    this.totalPackagesCarried = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransportAdModel.fromJson(Map<String, dynamic> d) {
    return TransportAdModel(
      id: d['id'] as String,
      transporterId: d['transporterId'] as String,
      transporterName: d['transporterName'] as String,
      transporterPhotoUrl: d['transporterPhotoUrl'] as String?,
      transporterRating: (d['transporterRating'] as num?)?.toDouble() ?? 0.0,
      transporterReviews: (d['transporterReviews'] as num?)?.toInt() ?? 0,
      departureCity: d['departureCity'] as String,
      arrivalCity: d['arrivalCity'] as String,
      flightDate: DateTime.parse(d['flightDate'] as String),
      flightTime: d['flightTime'] as String? ?? '',
      maxWeightKg: (d['maxWeightKg'] as num).toDouble(),
      pricePerKg: (d['pricePerKg'] as num).toDouble(),
      description: d['description'] as String? ?? '',
      status: d['status'] as String? ?? 'active',
      totalPackagesCarried: (d['totalPackagesCarried'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(d['createdAt'] as String),
      updatedAt: DateTime.parse(d['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'departureCity': departureCity,
        'arrivalCity': arrivalCity,
        'flightDate': flightDate.toIso8601String(),
        'flightTime': flightTime,
        'maxWeightKg': maxWeightKg,
        'pricePerKg': pricePerKg,
        'description': description,
      };

  TransportAdEntity toEntity() => TransportAdEntity(
        id: id,
        transporterId: transporterId,
        transporterName: transporterName,
        transporterPhotoUrl: transporterPhotoUrl,
        transporterRating: transporterRating,
        transporterReviews: transporterReviews,
        departureCity: departureCity,
        arrivalCity: arrivalCity,
        flightDate: flightDate,
        flightTime: flightTime,
        maxWeightKg: maxWeightKg,
        pricePerKg: pricePerKg,
        description: description,
        status: _statusFromString(status),
        totalPackagesCarried: totalPackagesCarried,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory TransportAdModel.fromEntity(TransportAdEntity e) => TransportAdModel(
        id: e.id,
        transporterId: e.transporterId,
        transporterName: e.transporterName,
        transporterPhotoUrl: e.transporterPhotoUrl,
        transporterRating: e.transporterRating,
        transporterReviews: e.transporterReviews,
        departureCity: e.departureCity,
        arrivalCity: e.arrivalCity,
        flightDate: e.flightDate,
        flightTime: e.flightTime,
        maxWeightKg: e.maxWeightKg,
        pricePerKg: e.pricePerKg,
        description: e.description,
        status: _statusToString(e.status),
        totalPackagesCarried: e.totalPackagesCarried,
        createdAt: e.createdAt,
        updatedAt: e.updatedAt,
      );

  static AdStatus _statusFromString(String s) {
    switch (s) {
      case 'active':
        return AdStatus.active;
      case 'inactive':
        return AdStatus.inactive;
      case 'pending':
        return AdStatus.pending;
      case 'rejected':
        return AdStatus.rejected;
      default:
        return AdStatus.expired;
    }
  }

  static String _statusToString(AdStatus s) {
    switch (s) {
      case AdStatus.active:
        return 'active';
      case AdStatus.inactive:
        return 'inactive';
      case AdStatus.expired:
        return 'expired';
      case AdStatus.pending:
        return 'pending';
      case AdStatus.rejected:
        return 'rejected';
    }
  }
}
