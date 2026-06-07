import 'package:equatable/equatable.dart';

enum OrderStatus { pending, accepted, rejected, inProgress, completed, cancelled }

class CancellationInfo {
  final String authorId;
  final String authorName;
  final String reason;
  final DateTime cancelledAt;

  const CancellationInfo({
    required this.authorId,
    required this.authorName,
    required this.reason,
    required this.cancelledAt,
  });
}

class TransportOrderEntity extends Equatable {
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
  final OrderStatus status;
  final bool reviewAuthorized;
  final CancellationInfo? cancellationInfo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransportOrderEntity({
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
    this.status = OrderStatus.accepted,
    this.reviewAuthorized = false,
    this.cancellationInfo,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get canLeaveReview =>
      reviewAuthorized && status == OrderStatus.completed;

  bool get isActive =>
      status == OrderStatus.accepted || status == OrderStatus.inProgress;

  @override
  List<Object?> get props => [id, orderNumber, status];
}
