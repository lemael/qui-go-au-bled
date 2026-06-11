import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:qui_go_au_bled/features/reviews/presentation/review_provider.dart';
import 'package:qui_go_au_bled/features/reviews/presentation/screens/reviews_screen.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

ReviewEntity _makeReview({
  String id = 'rev-001',
  String clientName = 'Alice Martin',
  double rating = 4.5,
  String comment = 'Très bon service',
  Duration ago = const Duration(days: 1),
}) =>
    ReviewEntity(
      id: id,
      orderId: 'order-001',
      orderNumber: 'ORD-001',
      transporterId: 'trans-001',
      transporterName: 'Ahmed Transport',
      clientId: 'client-001',
      clientName: clientName,
      rating: rating,
      comment: comment,
      punctuality: 4.0,
      communication: 5.0,
      packageCondition: 4.5,
      reliability: 4.0,
      createdAt: DateTime.now().subtract(ago),
    );

Widget _wrap({
  required String transporterId,
  required List<ReviewEntity> reviews,
}) {
  return ProviderScope(
    overrides: [
      transporterReviewsProvider.overrideWith(
        (ref, id) => Future.value(reviews),
      ),
    ],
    child: MaterialApp(
      home: ReviewsScreen(transporterId: transporterId),
    ),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    Intl.defaultLocale = 'fr_FR';
    await initializeDateFormatting('fr_FR');
  });

  group('ReviewsScreen — locale web', () {
    testWidgets(
      'affiche "Aucun avis" quand la liste est vide',
      (tester) async {
        await tester.pumpWidget(_wrap(
          transporterId: 'trans-001',
          reviews: [],
        ));
        await tester.pump();

        expect(find.text('Aucun avis'), findsOneWidget);
        expect(
          find.text('Ce transporteur n\'a pas encore reçu d\'avis.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'rend un avis sans crash LocaleDataException (bug locale web)',
      (tester) async {
        final review = _makeReview(ago: const Duration(hours: 3));

        await tester.pumpWidget(_wrap(
          transporterId: 'trans-001',
          reviews: [review],
        ));
        await tester.pump();

        // DateFormatter.relativeTime s'est exécuté sans exception
        expect(find.text('Il y a 3h'), findsOneWidget);
        expect(find.text('Alice Martin'), findsOneWidget);
        expect(find.text('Très bon service'), findsOneWidget);
      },
    );

    testWidgets(
      'rend plusieurs avis avec dates variées sans crash',
      (tester) async {
        final reviews = [
          _makeReview(
            id: 'r1',
            clientName: 'Bob',
            rating: 5.0,
            comment: 'Parfait',
            ago: const Duration(minutes: 45),
          ),
          _makeReview(
            id: 'r2',
            clientName: 'Claire',
            rating: 3.0,
            comment: 'Correct',
            ago: const Duration(days: 5),
          ),
          _makeReview(
            id: 'r3',
            clientName: 'David',
            rating: 4.0,
            comment: 'Bien',
            ago: const Duration(days: 14),
          ),
        ];

        await tester.pumpWidget(_wrap(
          transporterId: 'trans-001',
          reviews: reviews,
        ));
        await tester.pump();

        expect(find.text('Il y a 45 min'), findsOneWidget);
        expect(find.text('Il y a 5j'), findsOneWidget);
        // 14j > 7j → date formatée dd/MM/yyyy
        expect(
          find.textContaining(RegExp(r'\d{2}/\d{2}/\d{4}')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'affiche le résumé de note moyenne correctement',
      (tester) async {
        final reviews = [
          _makeReview(id: 'r1', rating: 4.0),
          _makeReview(id: 'r2', rating: 5.0),
        ];

        await tester.pumpWidget(_wrap(
          transporterId: 'trans-001',
          reviews: reviews,
        ));
        await tester.pump();

        // Moyenne = 4.5 (apparaît aussi dans les chips de critères)
        expect(find.text('4.5'), findsAtLeastNWidgets(1));
        expect(find.text('2 avis'), findsOneWidget);
      },
    );

    testWidgets(
      'affiche les critères de notation (ponctualité, communication…)',
      (tester) async {
        final review = _makeReview();

        await tester.pumpWidget(_wrap(
          transporterId: 'trans-001',
          reviews: [review],
        ));
        await tester.pump();

        expect(find.text('Ponctualité'), findsOneWidget);
        expect(find.text('Communication'), findsOneWidget);
        expect(find.text('Colis'), findsOneWidget);
        expect(find.text('Fiabilité'), findsOneWidget);
      },
    );
  });
}
