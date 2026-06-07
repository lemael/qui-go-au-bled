import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/auth_usecases.dart';

// ─── DataSource ──────────────────────────────────────────────────────────────

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ApiClient.instance.dio);
});

// ─── Repository ──────────────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

// ─── UseCases ────────────────────────────────────────────────────────────────

final signInUseCaseProvider =
    Provider<SignInUseCase>((ref) => SignInUseCase(ref.watch(authRepositoryProvider)));

final signUpUseCaseProvider =
    Provider<SignUpUseCase>((ref) => SignUpUseCase(ref.watch(authRepositoryProvider)));

final signOutUseCaseProvider =
    Provider<SignOutUseCase>((ref) => SignOutUseCase(ref.watch(authRepositoryProvider)));

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>(
    (ref) => ResetPasswordUseCase(ref.watch(authRepositoryProvider)));

// ─── Auth State (dérive du notifier) ─────────────────────────────────────────

final authStateProvider = Provider<AsyncValue<UserEntity?>>((ref) {
  return ref.watch(currentUserNotifierProvider);
});

// ─── Current User Notifier ───────────────────────────────────────────────────

class CurrentUserNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final Ref _ref;

  CurrentUserNotifier(this._ref) : super(const AsyncLoading()) {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final result = await _ref.read(authRepositoryProvider).getCurrentUser();
    state = result.fold(
      (_) => const AsyncData(null),
      (user) => AsyncData(user),
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await _ref.read(signInUseCaseProvider).call(
          email: email,
          password: password,
        );
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (user) => AsyncData(user),
    );
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
  }) async {
    state = const AsyncLoading();
    final result = await _ref.read(signUpUseCaseProvider).call(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          address: address,
        );
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (user) => AsyncData(user),
    );
  }

  Future<void> signOut() async {
    await _ref.read(signOutUseCaseProvider).call();
    state = const AsyncData(null);
  }

  Future<void> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    File? photo,
  }) async {
    final userId = state.value?.id;
    if (userId == null) return;
    state = const AsyncLoading();
    final result = await _ref.read(authRepositoryProvider).updateProfile(
          userId: userId,
          fullName: fullName,
          phone: phone,
          address: address,
          photo: photo,
        );
    state = result.fold(
      (failure) => AsyncError(failure.message, StackTrace.current),
      (user) => AsyncData(user),
    );
  }
}

final currentUserNotifierProvider =
    StateNotifierProvider<CurrentUserNotifier, AsyncValue<UserEntity?>>(
  (ref) => CurrentUserNotifier(ref),
);


// ─── Infrastructure providers ────────────────────────────────────────────────
