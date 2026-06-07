# Qui Go au Bled ✈️

**Application mobile Flutter de transport de colis entre voyageurs**

Une marketplace mobile permettant à des voyageurs en avion de proposer un service de transport de colis pour d'autres personnes.

---

## Stack Technique

| Technologie | Rôle |
|---|---|
| Flutter 3.x | Framework mobile (Android & iOS) |
| Dart 3.x | Langage |
| Firebase Auth | Authentification |
| Cloud Firestore | Base de données temps réel |
| Firebase Storage | Stockage photos |
| Firebase Cloud Messaging | Notifications push |
| PostgreSQL (Railway) | Analytics & données historiques |
| Riverpod 2.x | Gestion d'état |
| GoRouter | Navigation déclarative |
| Material 3 | Design System |
| Clean Architecture | Architecture logicielle |

---

## Architecture du Projet

```
lib/
├── main.dart                      # Point d'entrée
├── app.dart                       # Widget racine
├── firebase_options.dart          # Config Firebase (à configurer)
│
├── core/                          # Code partagé
│   ├── constants/
│   │   ├── app_constants.dart     # Constantes globales
│   │   ├── app_colors.dart        # Palette de couleurs
│   │   └── app_strings.dart       # Chaînes localisées
│   ├── errors/
│   │   ├── failures.dart          # Classes d'erreur domaine
│   │   └── exceptions.dart        # Exceptions data layer
│   ├── extensions/
│   │   └── string_extensions.dart
│   ├── theme/
│   │   └── app_theme.dart         # Thème Material 3
│   ├── utils/
│   │   ├── validators.dart        # Validateurs formulaires
│   │   ├── date_formatter.dart    # Formatage dates
│   │   └── transport_number_generator.dart  # TRP-XXXX-XXXXXX
│   └── widgets/                   # Widgets réutilisables
│       ├── app_button.dart
│       ├── app_text_field.dart
│       ├── loading_widget.dart
│       ├── star_rating_widget.dart
│       ├── empty_state_widget.dart
│       └── status_badge.dart
│
├── routing/
│   ├── app_router.dart            # GoRouter + ShellRoute
│   └── routes.dart                # Constantes de routes
│
└── features/
    ├── auth/                      # Authentification
    │   ├── domain/
    │   │   ├── entities/user_entity.dart
    │   │   ├── repositories/auth_repository.dart
    │   │   └── usecases/auth_usecases.dart
    │   ├── data/
    │   │   ├── models/user_model.dart
    │   │   ├── datasources/auth_remote_datasource.dart
    │   │   └── repositories/auth_repository_impl.dart
    │   └── presentation/
    │       ├── providers/auth_provider.dart
    │       └── screens/
    │           ├── splash_screen.dart
    │           ├── login_screen.dart
    │           ├── register_screen.dart
    │           ├── reset_password_screen.dart
    │           ├── profile_screen.dart
    │           └── edit_profile_screen.dart
    │
    ├── transport_ads/             # Annonces de transport
    │   ├── domain/
    │   ├── data/
    │   └── presentation/
    │       ├── screens/
    │       │   ├── home_screen.dart
    │       │   ├── search_screen.dart
    │       │   ├── ad_list_screen.dart
    │       │   ├── ad_detail_screen.dart
    │       │   ├── create_ad_screen.dart
    │       │   └── my_ads_screen.dart
    │       └── widgets/
    │           ├── ad_card_widget.dart
    │           └── search_filter_widget.dart
    │
    ├── transport_requests/        # Demandes de transport
    │   ├── domain/
    │   └── presentation/
    │       └── screens/
    │           ├── my_requests_screen.dart
    │           └── request_detail_screen.dart
    │
    ├── transport_orders/          # Commandes / Services
    │   ├── domain/
    │   └── presentation/
    │       └── screens/
    │           ├── my_transports_screen.dart
    │           ├── order_detail_screen.dart
    │           └── cancel_order_screen.dart
    │
    ├── transporter/               # Profil transporteur
    │   └── presentation/
    │       └── screens/transporter_profile_screen.dart
    │
    ├── reviews/                   # Système d'avis
    │   └── presentation/
    │       └── screens/
    │           ├── reviews_screen.dart
    │           └── create_review_screen.dart
    │
    ├── notifications/             # Notifications
    │   └── presentation/
    │       └── screens/notifications_screen.dart
    │
    ├── dashboard/                 # Tableau de bord transporteur
    │   └── presentation/
    │       └── screens/dashboard_screen.dart
    │
    └── settings/                  # Paramètres
        └── presentation/
            └── screens/settings_screen.dart
```

---

## États des Commandes

```
PENDING → ACCEPTED → IN_PROGRESS → COMPLETED
                ↘ REJECTED
ACCEPTED/IN_PROGRESS → CANCELLED
```

---

## Numérotation des transports

Format: `TRP-{ANNÉE}-{NUMÉRO_SÉQUENTIEL}`

Exemple: `TRP-2026-000145`

---

## Installation

### Prérequis

- Flutter SDK >= 3.2.0
- Dart SDK >= 3.2.0
- Android Studio / Xcode
- Compte Firebase
- Compte Railway (optionnel, pour PostgreSQL)

### 1. Cloner le projet

```bash
git clone https://github.com/votre-org/qui-go-au-bled.git
cd qui-go-au-bled
```

### 2. Installer les dépendances

```bash
flutter pub get
```

### 3. Configurer Firebase

```bash
# Installer FlutterFire CLI
dart pub global activate flutterfire_cli

# Configurer le projet Firebase
flutterfire configure --project=qui-go-au-bled
```

Ceci génèrera automatiquement `lib/firebase_options.dart`.

### 4. Configurer Firebase sur la console

Dans [Firebase Console](https://console.firebase.google.com):

1. **Authentication** → Activer Email/Password
2. **Firestore** → Créer la base de données en mode production
3. **Storage** → Activer Firebase Storage
4. **Cloud Messaging** → Activer FCM

### 5. Déployer les règles Firestore

```bash
firebase deploy --only firestore:rules
firebase deploy --only firestore:indexes
```

### 6. Ajouter les ressources (fonts et assets)

Créez les dossiers :
```
assets/fonts/    # Poppins-Regular.ttf, Poppins-Medium.ttf, Poppins-SemiBold.ttf, Poppins-Bold.ttf
assets/images/
assets/icons/
```

Téléchargez la police Poppins sur [Google Fonts](https://fonts.google.com/specimen/Poppins).

### 7. Générer le code (Riverpod + JSON serialization)

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 8. Configuration Android

Dans `android/app/build.gradle` :
```groovy
defaultConfig {
    minSdkVersion 21
    targetSdkVersion 34
}
```

Dans `android/app/src/main/AndroidManifest.xml`, ajouter :
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### 9. Configuration iOS

Dans `ios/Runner/Info.plist`, ajouter :
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Accès à la galerie pour votre photo de profil</string>
<key>NSCameraUsageDescription</key>
<string>Accès à la caméra pour votre photo de profil</string>
```

### 10. Lancer l'application

```bash
flutter run
```

---

## Configuration PostgreSQL (Railway)

### 1. Créer un projet Railway

1. Aller sur [railway.app](https://railway.app)
2. Créer un nouveau projet
3. Ajouter un service PostgreSQL
4. Copier la `DATABASE_URL`

### 2. Initialiser le schéma

```bash
psql $DATABASE_URL < database_schema.sql
```

### 3. Créer une API REST (optionnel)

Pour l'analytics, vous pouvez créer une API Node.js/Express sur Railway :

```bash
# Exemple d'endpoint pour les statistiques
GET /api/stats/transporter/:id
GET /api/stats/orders
```

L'app Flutter utilise `Dio` pour appeler ces endpoints.

---

## Variables d'environnement

Créer un fichier `.env` (non versionné) :

```env
RAILWAY_DATABASE_URL=postgresql://user:pass@host:port/db
FIREBASE_PROJECT_ID=qui-go-au-bled
```

---

## Notifications Push

Les notifications sont gérées via Firebase Cloud Messaging.

Pour déclencher des notifications automatiques lors des changements de statut, il est recommandé d'utiliser **Firebase Cloud Functions** :

```javascript
// functions/index.js
exports.onOrderStatusChange = functions.firestore
  .document('transport_orders/{orderId}')
  .onUpdate(async (change, context) => {
    const newStatus = change.after.data().status;
    const order = change.after.data();
    
    // Envoyer notification au client ou transporteur
    // selon le nouveau statut...
  });
```

---

## Tests

```bash
# Tests unitaires
flutter test

# Tests avec couverture
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

---

## Linting

```bash
flutter analyze
dart fix --apply
```

---

## Build Production

### Android (APK)
```bash
flutter build apk --release
```

### Android (App Bundle - Play Store)
```bash
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

---

## Fonctionnalités

| Fonctionnalité | Status |
|---|---|
| Authentification (Email/Password) | ✅ |
| Profil utilisateur | ✅ |
| Création d'annonces | ✅ |
| Recherche avec filtres | ✅ |
| Envoi de demandes | ✅ |
| Acceptation/refus | ✅ |
| Numéro de transport unique | ✅ |
| Début/fin de service | ✅ |
| Annulation avec motif | ✅ |
| Système d'avis sécurisé | ✅ |
| Calcul réputation auto | ✅ |
| Notifications in-app | ✅ |
| Push notifications (FCM) | ✅ |
| Tableau de bord | ✅ |
| Partage WhatsApp | ✅ |
| Mode sombre | ✅ |
| Design responsive | ✅ |

---

## Sécurité

- Les règles Firestore empêchent tout accès non autorisé
- Les avis ne peuvent être laissés que par des utilisateurs autorisés avec un numéro de transport valide
- Les statuts de commande ne peuvent être modifiés que par les parties concernées
- Les mots de passe sont gérés par Firebase Auth (bcrypt)
- Pas de données sensibles stockées en clair

---

## Licence

MIT License — © 2026 Qui Go au Bled
