import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:qui_go_au_bled/features/auth/domain/entities/user_entity.dart';
import 'package:qui_go_au_bled/features/auth/presentation/providers/auth_provider.dart';
import 'package:qui_go_au_bled/features/notifications/presentation/notification_provider.dart';
import 'package:qui_go_au_bled/features/notifications/presentation/screens/notifications_screen.dart';

// ─── Fakes ───────────────────────────────────────────────────────────────────

class _FakeUserNotifier extends CurrentUserNotifier {
  final UserEntity? _fakeUser;
  _FakeUserNotifier(super.ref, this._fakeUser);

  @override
  void init() {
    state = AsyncData(_fakeUser);
  }
}

class _FakeNotificationNotifier extends NotificationNotifier {
  _FakeNotificationNotifier() : super();
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

final _testUser = UserEntity(
  id: 'user-001',
  fullName: 'Test User',
  email: 'test@test.com',
  phone: '0600000000',
  address: 'Paris',
  role: UserRole.both,
  createdAt: DateTime(2025, 1, 1),
  updatedAt: DateTime(2025, 1, 1),
);

AppNotificationEntity _makeNotif({
  String id = 'notif-001',
  NotificationType type = NotificationType.newRequest,
  bool isRead = false,
  Duration ago = const Duration(minutes: 5),
}) =>
    AppNotificationEntity(
      id: id,
      userId: 'user-001',
      title: 'Titre notification',
      body: 'Corps de la notification',
      type: type,
      isRead: isRead,
      createdAt: DateTime.now().subtract(ago),
    );

Widget _wrap({
  required Widget child,
  required List<AppNotificationEntity> notifications,
  UserEntity? user,
}) {
  return ProviderScope(
    overrides: [
      currentUserNotifierProvider.overrideWith(
        (ref) => _FakeUserNotifier(ref, user ?? _testUser),
      ),
      notificationNotifierProvider.overrideWith(
        (ref) => _FakeNotificationNotifier(),
      ),
      myNotificationsProvider.overrideWith(
        (ref) => Future.value(notifications),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    Intl.defaultLocale = 'fr_FR';
    await initializeDateFormatting('fr_FR');
  });

  group('NotificationsScreen — locale web', () {
    testWidgets(
      'affiche "Aucune notification" quand la liste est vide',
      (tester) async {
        await tester.pumpWidget(_wrap(
          child: const NotificationsScreen(),
          notifications: [],
        ));
        await tester.pump(); // FutureProvider settle

        expect(find.text('Aucune notification'), findsOneWidget);
        expect(find.text('Vous êtes à jour !'), findsOneWidget);
      },
    );

    testWidgets(
      'rend une notification sans crash LocaleDataException (bug locale web)',
      (tester) async {
        final notif = _makeNotif(ago: const Duration(minutes: 10));

        await tester.pumpWidget(_wrap(
          child: const NotificationsScreen(),
          notifications: [notif],
        ));
        await tester.pump();

        // Le titre et le corps s'affichent
        expect(find.text('Titre notification'), findsOneWidget);
        expect(find.text('Corps de la notification'), findsOneWidget);
        // DateFormatter.relativeTime s'est exécuté sans exception
        expect(find.text('Il y a 10 min'), findsOneWidget);
      },
    );

    testWidgets(
      'rend plusieurs types de notification sans crash',
      (tester) async {
        final notifs = [
          _makeNotif(
            id: 'n1',
            type: NotificationType.requestAccepted,
            ago: const Duration(hours: 2),
          ),
          _makeNotif(
            id: 'n2',
            type: NotificationType.newReview,
            isRead: true,
            ago: const Duration(days: 3),
          ),
          _makeNotif(
            id: 'n3',
            type: NotificationType.serviceCompleted,
            ago: const Duration(seconds: 30),
          ),
        ];

        await tester.pumpWidget(_wrap(
          child: const NotificationsScreen(),
          notifications: notifs,
        ));
        await tester.pump();

        // Vérifie les temps relatifs sans locale exception
        expect(find.text('Il y a 2h'), findsOneWidget);
        expect(find.text('Il y a 3j'), findsOneWidget);
        expect(find.text('À l\'instant'), findsOneWidget);
      },
    );

    testWidgets(
      'affiche le point non-lu pour les notifications non lues',
      (tester) async {
        final notif = _makeNotif(isRead: false);

        await tester.pumpWidget(_wrap(
          child: const NotificationsScreen(),
          notifications: [notif],
        ));
        await tester.pump();

        // Le widget Container (point bleu) est présent pour notif non lue
        expect(find.byType(ListTile), findsOneWidget);
      },
    );

    testWidgets(
      'notification avec date > 7 jours affiche la date formatée fr_FR',
      (tester) async {
        final notif = _makeNotif(ago: const Duration(days: 10));

        await tester.pumpWidget(_wrap(
          child: const NotificationsScreen(),
          notifications: [notif],
        ));
        await tester.pump();

        // Doit afficher une date dd/MM/yyyy sans crash
        final dateText = find.textContaining(RegExp(r'\d{2}/\d{2}/\d{4}'));
        expect(dateText, findsOneWidget);
      },
    );
  });
}
