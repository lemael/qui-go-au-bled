import 'package:flutter_test/flutter_test.dart';
import 'package:qui_go_au_bled/features/auth/domain/entities/user_entity.dart';

final _kTestDate = DateTime(2026, 1, 1);

void main() {
  group('UserEntity', () {
    final user = UserEntity(
      id: 'user-001',
      fullName: 'Jean Dupont',
      email: 'jean@test.com',
      phone: '+33612345678',
      address: 'Paris, France',
      role: UserRole.transporter,
      averageRating: 4.6,
      totalReviews: 28,
      createdAt: _kTestDate,
      updatedAt: _kTestDate,
    );

    test('isTransporter returns true for transporter role', () {
      expect(user.isTransporter, isTrue);
      expect(user.isClient, isFalse);
    });

    test('isClient returns true for client role', () {
      final client = UserEntity(
        id: 'user-002',
        fullName: 'Marie Martin',
        email: 'marie@test.com',
        phone: '+33611111111',
        address: 'Lyon, France',
        role: UserRole.client,
        createdAt: _kTestDate,
        updatedAt: _kTestDate,
      );
      expect(client.isClient, isTrue);
      expect(client.isTransporter, isFalse);
    });

    test('starCount returns 5 for rating >= 4.5', () {
      expect(user.starCount, equals(5));
    });

    test('starCount returns 4 for rating >= 3.5', () {
      final u = UserEntity(
        id: 'u',
        fullName: 'Test',
        email: 'test@test.com',
        phone: '+33600000000',
        address: 'Paris',
        role: UserRole.transporter,
        averageRating: 4.2,
        createdAt: _kTestDate,
        updatedAt: _kTestDate,
      );
      expect(u.starCount, equals(4));
    });

    test('copyWith updates only provided fields', () {
      final updated = user.copyWith(fullName: 'Pierre Dupont');
      expect(updated.fullName, equals('Pierre Dupont'));
      expect(updated.email, equals(user.email));
      expect(updated.role, equals(user.role));
    });

    test('props equality works correctly', () {
      final sameUser = UserEntity(
        id: 'user-001',
        fullName: 'Jean Dupont',
        email: 'jean@test.com',
        phone: '+33612345678',
        address: 'Paris, France',
        role: UserRole.transporter,
        averageRating: 4.6,
        totalReviews: 28,
        createdAt: _kTestDate,
        updatedAt: _kTestDate,
      );
      expect(user, equals(sameUser));
    });
  });
}
