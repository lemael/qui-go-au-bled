import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user_entity.dart';

part 'user_model.g.dart';

@JsonSerializable(explicitToJson: true)
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String address;
  final String? photoUrl;
  final String role;
  final double averageRating;
  final int totalReviews;
  final String? fcmToken;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
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

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserEntity toEntity() => UserEntity(
        id: id,
        fullName: fullName,
        email: email,
        phone: phone,
        address: address,
        photoUrl: photoUrl,
        role: role == 'transporter'
            ? UserRole.transporter
            : role == 'client'
                ? UserRole.client
                : role == 'admin'
                    ? UserRole.admin
                    : UserRole.both,
        averageRating: averageRating,
        totalReviews: totalReviews,
        fcmToken: fcmToken,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory UserModel.fromEntity(UserEntity entity) => UserModel(
        id: entity.id,
        fullName: entity.fullName,
        email: entity.email,
        phone: entity.phone,
        address: entity.address,
        photoUrl: entity.photoUrl,
        role: entity.role == UserRole.transporter
            ? 'transporter'
            : entity.role == UserRole.client
                ? 'client'
                : 'both',
        averageRating: entity.averageRating,
        totalReviews: entity.totalReviews,
        fcmToken: entity.fcmToken,
        createdAt: entity.createdAt,
        updatedAt: entity.updatedAt,
      );
}
