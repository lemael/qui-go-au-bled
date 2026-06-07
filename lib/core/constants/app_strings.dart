class AppStrings {
  AppStrings._();

  // General
  static const String appName = 'Qui Go au Bled';
  static const String loading = 'Chargement...';
  static const String retry = 'Réessayer';
  static const String cancel = 'Annuler';
  static const String confirm = 'Confirmer';
  static const String save = 'Enregistrer';
  static const String close = 'Fermer';
  static const String next = 'Suivant';
  static const String back = 'Retour';
  static const String yes = 'Oui';
  static const String no = 'Non';
  static const String or = 'ou';
  static const String edit = 'Modifier';
  static const String delete = 'Supprimer';
  static const String share = 'Partager';
  static const String noData = 'Aucune donnée disponible';
  static const String networkError = 'Erreur de connexion. Vérifiez votre réseau.';
  static const String unknownError = 'Une erreur est survenue. Réessayez.';

  // Auth
  static const String login = 'Se connecter';
  static const String register = 'Créer un compte';
  static const String logout = 'Se déconnecter';
  static const String email = 'Email';
  static const String password = 'Mot de passe';
  static const String confirmPassword = 'Confirmer le mot de passe';
  static const String fullName = 'Nom complet';
  static const String phone = 'Téléphone';
  static const String address = 'Adresse';
  static const String forgotPassword = 'Mot de passe oublié ?';
  static const String resetPassword = 'Réinitialiser le mot de passe';
  static const String noAccount = 'Pas encore de compte ?';
  static const String alreadyAccount = 'Déjà un compte ?';
  static const String profilePhoto = 'Photo de profil';

  // Roles
  static const String transporter = 'Transporteur';
  static const String client = 'Client';

  // Transport Ads
  static const String createAd = 'Créer une annonce';
  static const String myAds = 'Mes annonces';
  static const String adDetails = 'Détails de l\'annonce';
  static const String departureCity = 'Ville de départ';
  static const String arrivalCity = 'Ville d\'arrivée';
  static const String flightDate = 'Date du vol';
  static const String flightTime = 'Heure du vol';
  static const String maxWeight = 'Poids maximum (kg)';
  static const String pricePerKg = 'Prix par kg (€)';
  static const String description = 'Description';
  static const String activeAd = 'Annonce active';
  static const String adPublished = 'Annonce publiée avec succès';
  static const String shareOnWhatsApp = 'Partager sur WhatsApp';

  // Requests
  static const String sendRequest = 'Envoyer une demande';
  static const String myRequests = 'Mes demandes';
  static const String requestSent = 'Demande envoyée';
  static const String acceptRequest = 'Accepter';
  static const String rejectRequest = 'Refuser';
  static const String requestAccepted = 'Demande acceptée';
  static const String requestRejected = 'Demande refusée';

  // Orders
  static const String myTransports = 'Mes transports';
  static const String startService = 'Commencer le service';
  static const String completeService = 'Service terminé';
  static const String cancelService = 'Annuler le service';
  static const String transportNumber = 'Numéro de transport';
  static const String orderDetails = 'Détails de la commande';

  // Cancellation reasons
  static const List<String> cancellationReasons = [
    'Voyage annulé',
    'Colis non conforme',
    'Client absent',
    'Transporteur indisponible',
    'Autre',
  ];

  // Reviews
  static const String leaveReview = 'Laisser un avis';
  static const String reviews = 'Avis';
  static const String rating = 'Note';
  static const String comment = 'Commentaire';
  static const String punctuality = 'Ponctualité';
  static const String communication = 'Communication';
  static const String packageCondition = 'État du colis';
  static const String reliability = 'Fiabilité';

  // Notifications
  static const String notifications = 'Notifications';
  static const String markAllRead = 'Tout marquer comme lu';

  // Dashboard
  static const String dashboard = 'Tableau de bord';
  static const String totalTransports = 'Total transports';
  static const String successfulTransports = 'Transports réussis';
  static const String cancellations = 'Annulations';
  static const String successRate = 'Taux de réussite';
  static const String averageRating = 'Note moyenne';

  // Settings
  static const String settings = 'Paramètres';
  static const String account = 'Mon compte';
  static const String security = 'Sécurité';
  static const String about = 'À propos';
}
