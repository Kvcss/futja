class FormValidators {
  FormValidators._();

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe $fieldName';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o e-mail';
    }
    if (!value.contains('@')) {
      return 'E-mail inválido';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Informe a senha';
    }
    if (value.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres';
    }
    return null;
  }

  static String? validatePositiveInt(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe $fieldName';
    }

    final parsed = int.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Número inválido';
    }

    return null;
  }
}