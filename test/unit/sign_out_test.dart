import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qui_go_au_bled/core/errors/failures.dart';
import 'package:qui_go_au_bled/features/auth/domain/entities/user_entity.dart';
import 'package:qui_go_au_bled/features/auth/domain/repositories/auth_repository.dart';
import 'package:qui_go_au_bled/features/auth/domain/usecases/auth_usecases.dart';
import 'package:qui_go_au_bled/features/auth/presentation/providers/auth_provider.dart';

// ─── Fake Repository ─────────────────────────────────────────────────────────

class _FakeAuthRepository implements AuthRepository {
  bool signOutCalled = false;
  Either<Failure, void> signOutResult = const Right(null);
  UserEntity? currentUser;

  @override
  Future<Either<Failure, void>> signOut() async {
    signOutCalled = true;
    return signOutResult;
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async =>
      Right(currentUser);

  // ── Non implémentés pour ces tests ──────────────────────────────────────────
  @override
  Future<Either<Failure, UserEntity>> signIn({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> resetPassword(String email) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    required String userId,
    String? fullName,
    String? phone,
    String? address,
    File? photo,
  }) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, UserEntity>> getUserById(String userId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, void>> updateFcmToken(
          String userId, String token) =>
      throw UnimplementedError();
}

// ─── Données de test ─────────────────────────────────────────────────────────

final _testUser = UserEntity(
  id: 'user-001',
  fullName: 'Alice Dupont',
  email: 'alice@test.com',
  phone: '0600000000',
  address: 'Lyon',
  role: UserRole.client,
  createdAt: DateTime(2025, 1, 1),
  updatedAt: DateTime(2025, 1, 1),
);

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('SignOutUseCase', () {
    test('appelle repository.signOut() et retourne Right(null)', () async {
      final repo = _FakeAuthRepository();
      final useCase = SignOutUseCase(repo);

      final result = await useCase.call();

      expect(result, equals(const Right<Failure, void>(null)));
      expect(repo.signOutCalled, isTrue);
    });

    test('propage un ServerFailure quand le repository échoue', () async {
      final repo = _FakeAuthRepository()
        ..signOutResult = const Left(ServerFailure('Erreur réseau'));
      final useCase = SignOutUseCase(repo);

      final result = await useCase.call();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Devait retourner un Left'),
      );
    });
  });

  group('CurrentUserNotifier — signOut()', () {
    late _FakeAuthRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = _FakeAuthRepository()..currentUser = _testUser;
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
      addTearDown(container.dispose);
    });

    test('état initial charge l\'utilisateur depuis le repository', () async {
      // Attend que _loadCurrentUser() se termine
      await container
          .read(currentUserNotifierProvider.notifier)
          .future
          .catchError((_) => null);

      final state = container.read(currentUserNotifierProvider);
      expect(state.value, equals(_testUser));
    });

    test('après signOut(), l\'état devient AsyncData(null)', () async {
      // Attend l'init
      await container
          .read(currentUserNotifierProvider.notifier)
          .future
          .catchError((_) => null);

      await container
          .read(currentUserNotifierProvider.notifier)
          .signOut();

      final state = container.read(currentUserNotifierProvider);
      expect(state, equals(const AsyncData<UserEntity?>(null)));
      expect(fakeRepo.signOutCalled, isTrue);
    });

    test(
        'après signOut(), l\'état est null même si repository renvoie une erreur',
        () async {
      fakeRepo.signOutResult =
          const Left(ServerFailure('Impossible de contacter le serveur'));

      await container
          .read(currentUserNotifierProvider.notifier)
          .future
          .catchError((_) => null);

      await container
          .read(currentUserNotifierProvider.notifier)
          .signOut();

      // Le notifier force state = AsyncData(null) quoi qu'il arrive
      final state = container.read(currentUserNotifierProvider);
      expect(state, equals(const AsyncData<UserEntity?>(null)));
    });

    test(
        'authStateProvider retourne null après signOut()',
        () async {
      await container
          .read(currentUserNotifierProvider.notifier)
          .future
          .catchError((_) => null);

      await container
          .read(currentUserNotifierProvider.notifier)
          .signOut();

      final authState = container.read(authStateProvider);
      expect(authState.value, isNull);
    });
  });
}

// Extension pour attendre la fin du chargement initial du notifier
extension on CurrentUserNotifier {
  Future<void> get future async {
    // Attend que l'état ne soit plus AsyncLoading
    while (state.isLoading) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
  }
}
