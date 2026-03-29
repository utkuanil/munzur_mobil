class Validators {
  static bool isMunzurEmail(String email) {
    return email.trim().toLowerCase().endsWith('@munzur.edu.tr');
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-posta zorunludur';
    }

    final email = value.trim().toLowerCase();

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Geçerli bir e-posta girin';
    }

    if (!isMunzurEmail(email)) {
      return 'Sadece @munzur.edu.tr uzantılı e-posta kullanılabilir';
    }

    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.length < 6) {
      return 'Şifre en az 6 karakter olmalıdır';
    }
    return null;
  }

  static String? validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return '$label zorunludur';
    }
    return null;
  }
}