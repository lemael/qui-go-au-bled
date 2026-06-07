import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/token_service.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> signIn({required String email, required String password});
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
  });
  Future<void> signOut();
  Future<void> resetPassword(String email);
  Future<UserModel?> getCurrentUser();
  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? address,
    File? photo,
  });
  Future<UserModel> getUserById(String userId);
  Future<void> updateFcmToken(String userId, String token);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      await TokenService.saveToken(response.data['token'] as String);
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(ApiClient.errorMessage(e));
    }
  }

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
        'phone': phone,
        'address': address,
      });
      await TokenService.saveToken(response.data['token'] as String);
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(ApiClient.errorMessage(e));
    }
  }

  @override
  Future<void> signOut() async {
    await TokenService.clearToken();
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _dio.post('/auth/reset-password', data: {'email': email});
    } on DioException catch (e) {
      throw AuthException(ApiClient.errorMessage(e));
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final token = await TokenService.getToken();
    if (token == null) return null;
    try {
      final response = await _dio.get('/auth/me');
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await TokenService.clearToken();
        return null;
      }
      throw AuthException(ApiClient.errorMessage(e));
    }
  }

  @override
  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? address,
    File? photo,
  }) async {
    try {
      final formData = FormData.fromMap({
        if (fullName != null) 'fullName': fullName,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (photo != null)
          'photo': await MultipartFile.fromFile(photo.path, filename: 'photo.jpg'),
      });
      final response = await _dio.patch('/users/profile', data: formData);
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(ApiClient.errorMessage(e));
    }
  }

  @override
  Future<UserModel> getUserById(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw AuthException(ApiClient.errorMessage(e));
    }
  }

  @override
  Future<void> updateFcmToken(String userId, String token) async {
    try {
      await _dio.patch('/users/fcm-token', data: {'token': token});
    } catch (_) {}
  }
}
