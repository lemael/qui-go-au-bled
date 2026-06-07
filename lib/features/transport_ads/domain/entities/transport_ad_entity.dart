import 'package:equatable/equatable.dart';

enum AdStatus { active, inactive, expired }

class TransportAdEntity extends Equatable {
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
  final AdStatus status;
  final int totalPackagesCarried;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransportAdEntity({
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
    this.status = AdStatus.active,
    this.totalPackagesCarried = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isActive => status == AdStatus.active;
  bool get isUpcoming => flightDate.isAfter(DateTime.now());

  String get shareText =>
      'Voyage de $departureCity vers $arrivalCity le ${flightDate.day}/${flightDate.month}/${flightDate.year} — '
      'Je peux transporter jusqu\'à ${maxWeightKg}kg à ${pricePerKg}€/kg. '
      'Contactez-moi via Qui Go au Bled !';

  @override
  List<Object?> get props => [
        id,
        transporterId,
        departureCity,
        arrivalCity,
        flightDate,
        status,
      ];
}
