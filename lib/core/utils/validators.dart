class Validators {
  Validators._();

  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'L\'email est requis';
    final emailRegex = RegExp(r'^[\w.-]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) return 'Adresse email invalide';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Le mot de passe est requis';
    if (value.length < 8) return 'Minimum 8 caractères';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Confirmez votre mot de passe';
    if (value != password) return 'Les mots de passe ne correspondent pas';
    return null;
  }

  static String? required(String? value, [String fieldName = 'Ce champ']) {
    if (value == null || value.trim().isEmpty) return '$fieldName est requis';
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Le nom complet est requis';
    if (value.trim().length < 3) return 'Minimum 3 caractères';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) return 'Le téléphone est requis';
    final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return 'Numéro de téléphone invalide';
    }
    return null;
  }

  static String? price(String? value) {
    if (value == null || value.isEmpty) return 'Le prix est requis';
    final price = double.tryParse(value);
    if (price == null) return 'Prix invalide';
    if (price <= 0) return 'Le prix doit être supérieur à 0';
    return null;
  }

  static String? weight(String? value) {
    if (value == null || value.isEmpty) return 'Le poids est requis';
    final weight = double.tryParse(value);
    if (weight == null) return 'Poids invalide';
    if (weight <= 0) return 'Le poids doit être supérieur à 0';
    if (weight > 50) return 'Le poids maximum est 50 kg';
    return null;
  }

  static String? minLength(String? value, int min, [String? fieldName]) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'Ce champ'} est requis';
    }
    if (value.length < min) return 'Minimum $min caractères';
    return null;
  }
}
