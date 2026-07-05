/// Règles de validation des formulaires — mêmes règles que les schémas zod
/// de la webapp (login/register).
library;

final _emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? validateEmail(String? value) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return 'Email requis';
  if (!_emailRegex.hasMatch(v)) return 'Email invalide';
  return null;
}

String? validatePassword(String? value) {
  final v = value ?? '';
  if (v.isEmpty) return 'Mot de passe requis';
  if (v.length < 8) {
    return 'Le mot de passe doit contenir au moins 8 caractères';
  }
  return null;
}

String? validateName(String? value, String label) {
  final v = value?.trim() ?? '';
  if (v.isEmpty) return '$label requis';
  if (v.length < 2) return '$label doit contenir au moins 2 caractères';
  return null;
}

String? validatePasswordConfirmation(String password, String? confirmation) {
  if (password != (confirmation ?? '')) {
    return 'Les mots de passe ne correspondent pas';
  }
  return null;
}
