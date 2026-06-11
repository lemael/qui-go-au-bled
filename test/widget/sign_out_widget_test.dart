import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qui_go_au_bled/core/errors/failures.dart';
import 'package:qui_go_au_bled/features/auth/domain/entities/user_entity.dart';
import 'package:qui_go_au_bled/features/auth/domain/repositories/auth_repository.dart';
import 'package:qui_go_au_bled/features/auth/presentation/providers/auth_provider.dart';
import 'package:qui_go_au_bled/features/settings/presentation/screens/settings_screen.dart';
import 'package:qui_go_au_bled/features/auth/presentation/screens/profile_screen.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:qui_go_au_bled/features/transport_ads/domain/entities/transport_ad_entity.dart';
import 'package:qui_go_au_bled/features/transport_ads/presentation/providers/transport_ad_provider.dart';
import 'package:qui_go_au_bled/routing/app_router.dart';
import 'package:qui_go_au_bled/routing/routes.dart';

// ─── Fake Repository ─────────────────────────────────────────────────────────

class _FakeAuthRepository implements AuthRepository {
  bool signOutCalled = false;
  UserEntity? currentUser;

  @override
  Future<Either<Failure, void>> signOut() async {
    signOutCalled = true;
    return const Right(null);
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async =>
      Right(currentUser);

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
  Future<Either<Failure, void>> updateFcmToken(String userId, String token) =>
      throw UnimplementedError();
}

// ─── Données de test ─────────────────────────────────────────────────────────

final _clientUser = UserEntity(
  id: 'user-client',
  fullName: 'Marie Client',
  email: 'marie@test.com',
  phone: '0600000000',
  address: 'Paris',
  role: UserRole.client,
  createdAt: DateTime(2025, 1, 1),
  updatedAt: DateTime(2025, 1, 1),
);

// ─── Helpers ─────────────────────────────────────────────────────────────────

Widget _wrapSettings(_FakeAuthRepository repo) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
    ],
    child: const MaterialApp(home: SettingsScreen()),
  );
}

Widget _wrapProfile(_FakeAuthRepository repo) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      myTransporterAdsProvider.overrideWith((_) => Future.value([])),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  // ── SettingsScreen ──────────────────────────────────────────────────────────

  group('SettingsScreen — bouton Se déconnecter', () {
    // Helper : scroll jusqu'au bouton logout (en bas du ListView)
    Future<void> scrollToLogout(WidgetTester tester) async {
      final logoutFinder =
          find.text('Se déconnecter', skipOffstage: false);
      await tester.ensureVisible(logoutFinder);
      await tester.pump();
    }

    testWidgets(
      'le bouton "Se déconnecter" existe dans la page (même hors écran)',
      (tester) async {
        final repo = _FakeAuthRepository()..currentUser = _clientUser;
        await tester.pumpWidget(_wrapSettings(repo));
        await tester.pumpAndSettle();

        // skipOffstage: false car le bouton peut être sous le fold
        expect(
            find.text('Se déconnecter', skipOffstage: false), findsOneWidget);
        expect(find.byIcon(Icons.logout_rounded, skipOffstage: false),
            findsOneWidget);
      },
    );

    testWidgets(
      'taper le bouton appelle signOut() et met l\'état à null',
      (tester) async {
        final repo = _FakeAuthRepository()..currentUser = _clientUser;
        await tester.pumpWidget(_wrapSettings(repo));
        await tester.pumpAndSettle();

        // État initial : utilisateur connecté
        final container = ProviderScope.containerOf(
          tester.element(find.byType(SettingsScreen)),
        );
        expect(container.read(currentUserNotifierProvider).value,
            equals(_clientUser));
        expect(repo.signOutCalled, isFalse);

        // Scroll jusqu'au bouton puis tape
        await scrollToLogout(tester);
        await tester.tap(find.text('Se déconnecter'));
        await tester.pumpAndSettle();

        // signOut() a été appelé
        expect(repo.signOutCalled, isTrue);
        // L'état utilisateur est null
        expect(container.read(currentUserNotifierProvider).value, isNull);
      },
    );

    testWidgets(
      'le bouton de déconnexion est cliquable (onPressed non null)',
      (tester) async {
        final repo = _FakeAuthRepository()..currentUser = _clientUser;
        await tester.pumpWidget(_wrapSettings(repo));
        await tester.pumpAndSettle();

        await scrollToLogout(tester);
        final button = tester.widget<OutlinedButton>(
          find.ancestor(
            of: find.text('Se déconnecter'),
            matching: find.byType(OutlinedButton),
          ),
        );
        expect(button.onPressed, isNotNull);
      },
    );
  });

  // ── ProfileScreen ───────────────────────────────────────────────────────────

  group('ProfileScreen — dialog de déconnexion', () {
    testWidgets(
      'le bouton "Se déconnecter" ouvre un dialog de confirmation',
      (tester) async {
        final repo = _FakeAuthRepository()..currentUser = _clientUser;
        await tester.pumpWidget(_wrapProfile(repo));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.logout_rounded));
        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        expect(
          find.text('Êtes-vous sûr de vouloir vous déconnecter ?'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'appuyer "Annuler" ferme le dialog SANS appeler signOut()',
      (tester) async {
        final repo = _FakeAuthRepository()..currentUser = _clientUser;
        await tester.pumpWidget(_wrapProfile(repo));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.logout_rounded));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Annuler'));
        await tester.pumpAndSettle();

        // Le dialog est fermé
        expect(find.byType(AlertDialog), findsNothing);
        // signOut() N'a PAS été appelé
        expect(repo.signOutCalled, isFalse);
      },
    );

    testWidgets(
      'confirmer la déconnexion appelle signOut() et met l\'état à null',
      (tester) async {
        final repo = _FakeAuthRepository()..currentUser = _clientUser;
        await tester.pumpWidget(_wrapProfile(repo));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.logout_rounded));
        await tester.pumpAndSettle();

        // Confirme dans le dialog — on cible l'ElevatedButton (pas le titre)
        final confirmButton = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(ElevatedButton),
        );
        await tester.tap(confirmButton);
        // pumpAndSettle bloquerait à cause du CircularProgressIndicator
        // qui apparaît quand user == null. On utilise pump() à la place.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(repo.signOutCalled, isTrue);

        final container = ProviderScope.containerOf(
          tester.element(find.byType(Scaffold).first),
        );
        expect(container.read(currentUserNotifierProvider).value, isNull);
      },
    );

    testWidgets(
      'le dialog affiche les boutons Annuler et Se déconnecter',
      (tester) async {
        final repo = _FakeAuthRepository()..currentUser = _clientUser;
        await tester.pumpWidget(_wrapProfile(repo));
        await tester.pumpAndSettle();

        await tester.tap(find.byIcon(Icons.logout_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Annuler'), findsOneWidget);
        // Le dialog contient "Se déconnecter" (titre + bouton confirm)
        expect(
          find.descendant(
            of: find.byType(AlertDialog),
            matching: find.text('Se déconnecter'),
          ),
          findsAtLeastNWidgets(1),
        );
      },
    );
  });

  // ── Redirection GoRouter ─────────────────────────────────────────────────────

  group('Déconnexion — redirection GoRouter vers /login', () {
    testWidgets(
      'après signOut(), GoRouter redirige vers /login',
      (tester) async {
        final repo = _FakeAuthRepository()..currentUser = _clientUser;
        // Stream vide pour éviter les appels HTTP dans HomeScreen
        final adsController = StreamController<List<TransportAdEntity>>();
        adsController.add([]);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWithValue(repo),
              activeAdsStreamProvider
                  .overrideWith((_) => adsController.stream),
              myTransporterAdsProvider.overrideWith((_) => Future.value([])),
            ],
            child: Consumer(builder: (context, ref, _) {
              final router = ref.watch(appRouterProvider);
              return MaterialApp.router(routerConfig: router);
            }),
          ),
        );

        // Pump 2.1s pour laisser la SplashScreen (2s delay) naviguer vers /home
        await tester.pump(const Duration(milliseconds: 2100));
        await tester.pump(); // traite le context.go('/home')
        await tester.pump(); // frame de rendu

        final container = ProviderScope.containerOf(
          tester.element(find.byType(Consumer)),
        );

        // Vérifie qu'on est bien sur /home avant de se déconnecter
        final routerBefore = container.read(appRouterProvider);
        expect(
          routerBefore.routerDelegate.currentConfiguration.uri.path,
          equals(AppRoutes.home),
        );

        // Déconnexion
        await container
            .read(currentUserNotifierProvider.notifier)
            .signOut();

        // Laisse Riverpod propager → _AuthListenable.notifyListeners() → redirect
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Vérifie la redirection vers /login
        final routerAfter = container.read(appRouterProvider);
        expect(
          routerAfter.routerDelegate.currentConfiguration.uri.path,
          equals(AppRoutes.login),
        );

        await adsController.close();
      },
    );
  });
}

// ─── Fake Notifier ───────────────────────────────────────────────────────────
