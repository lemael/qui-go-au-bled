import 'package:flutter_test/flutter_test.dart';
import 'package:qui_go_au_bled/features/transport_ads/domain/entities/transport_ad_entity.dart';

void main() {
  final kFlightDate = DateTime(2026, 8, 15);
  final kPastDate = DateTime(2020, 1, 1);

  group('TransportAdEntity', () {
    late TransportAdEntity activeAd;
    late TransportAdEntity inactiveAd;

    setUp(() {
      activeAd = TransportAdEntity(
        id: 'ad-001',
        transporterId: 'transporter-001',
        transporterName: 'Ali Benali',
        transporterRating: 4.8,
        transporterReviews: 15,
        departureCity: 'Paris',
        arrivalCity: 'Alger',
        flightDate: kFlightDate,
        flightTime: '14:30',
        maxWeightKg: 20,
        pricePerKg: 8,
        description: 'Colis électroniques acceptés',
        status: AdStatus.active,
        createdAt: DateTime(2026, 6, 1),
        updatedAt: DateTime(2026, 6, 1),
      );

      inactiveAd = activeAd.copyWith(status: AdStatus.inactive);
    });

    test('isActive returns true for active status', () {
      expect(activeAd.isActive, isTrue);
    });

    test('isActive returns false for inactive status', () {
      // Since entity is immutable, we create a new one
      final ad = TransportAdEntity(
        id: 'ad-002',
        transporterId: 'tr-001',
        transporterName: 'Test',
        departureCity: 'Paris',
        arrivalCity: 'Tunis',
        flightDate: kFlightDate,
        flightTime: '10:00',
        maxWeightKg: 10,
        pricePerKg: 5,
        description: '',
        status: AdStatus.inactive,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      expect(ad.isActive, isFalse);
    });

    test('isUpcoming returns true for future flights', () {
      expect(activeAd.isUpcoming, isTrue);
    });

    test('shareText contains key info', () {
      expect(activeAd.shareText, contains('Paris'));
      expect(activeAd.shareText, contains('Alger'));
      expect(activeAd.shareText, contains('20'));
      expect(activeAd.shareText, contains('8'));
    });
  });
}

extension on TransportAdEntity {
  TransportAdEntity copyWith({AdStatus? status}) {
    return TransportAdEntity(
      id: id,
      transporterId: transporterId,
      transporterName: transporterName,
      departureCity: departureCity,
      arrivalCity: arrivalCity,
      flightDate: flightDate,
      flightTime: flightTime,
      maxWeightKg: maxWeightKg,
      pricePerKg: pricePerKg,
      description: description,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
