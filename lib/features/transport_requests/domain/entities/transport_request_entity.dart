import 'package:equatable/equatable.dart';

enum RequestStatus { pending, accepted, rejected }

class TransportRequestEntity extends Equatable {
  final String id;
  final String adId;
  final String transporterId;
  final String transporterName;
  final String clientId;
  final String clientName;
  final String? clientPhotoUrl;
  final String? message;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransportRequestEntity({
    required this.id,
    required this.adId,
    required this.transporterId,
    required this.transporterName,
    required this.clientId,
    required this.clientName,
    this.clientPhotoUrl,
    this.message,
    this.status = RequestStatus.pending,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isPending => status == RequestStatus.pending;
  bool get isAccepted => status == RequestStatus.accepted;
  bool get isRejected => status == RequestStatus.rejected;

  @override
  List<Object?> get props => [id, adId, clientId, transporterId, status];
}
