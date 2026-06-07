import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _repository;
  const SignInUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
  }) {
    return _repository.signIn(email: email, password: password);
  }
}

class SignUpUseCase {
  final AuthRepository _repository;
  const SignUpUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String address,
  }) {
    return _repository.signUp(
      email: email,
      password: password,
      fullName: fullName,
      phone: phone,
      address: address,
    );
  }
}

class SignOutUseCase {
  final AuthRepository _repository;
  const SignOutUseCase(this._repository);

  Future<Either<Failure, void>> call() => _repository.signOut();
}

class ResetPasswordUseCase {
  final AuthRepository _repository;
  const ResetPasswordUseCase(this._repository);

  Future<Either<Failure, void>> call(String email) =>
      _repository.resetPassword(email);
}

class GetCurrentUserUseCase {
  final AuthRepository _repository;
  const GetCurrentUserUseCase(this._repository);

  Future<Either<Failure, UserEntity?>> call() => _repository.getCurrentUser();
}

class GetUserByIdUseCase {
  final AuthRepository _repository;
  const GetUserByIdUseCase(this._repository);

  Future<Either<Failure, UserEntity>> call(String userId) =>
      _repository.getUserById(userId);
}
