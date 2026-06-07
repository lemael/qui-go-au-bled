import 'package:equatable/equatable.dart';

enum UserRole { transporter, client, both, admin }

class UserEntity extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String? photoUrl;
  final UserRole role;
  final double averageRating;
  final int totalReviews;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.address,
    this.photoUrl,
    required this.role,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.fcmToken,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isTransporter => role == UserRole.transporter || role == UserRole.both;
  bool get isClient => role == UserRole.client || role == UserRole.both;

  int get starCount {
    if (averageRating >= 4.5) return 5;
    if (averageRating >= 3.5) return 4;
    if (averageRating >= 2.5) return 3;
    if (averageRating >= 1.5) return 2;
    if (averageRating >= 0.5) return 1;
    return 0;
  }

  UserEntity copyWith({
    String? fullName,
    String? phone,
    String? address,
    String? photoUrl,
    UserRole? role,
    double? averageRating,
    int? totalReviews,
    String? fcmToken,
  }) {
    return UserEntity(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        fullName,
        email,
        phone,
        address,
        photoUrl,
        role,
        averageRating,
        totalReviews,
        createdAt,
      ];
}
