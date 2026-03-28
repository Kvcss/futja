import 'package:flutter_test/flutter_test.dart';
import 'package:futja_app/core/form_validators.dart';

void main() {
  group('FormValidators', () {
    test('validateEmail deve falhar com email inválido', () {
      expect(
        FormValidators.validateEmail('teste'),
        'E-mail inválido',
      );
    });

    test('validateEmail deve aceitar email válido', () {
      expect(
        FormValidators.validateEmail('teste@email.com'),
        isNull,
      );
    });

    test('validatePassword deve falhar com senha curta', () {
      expect(
        FormValidators.validatePassword('123'),
        'A senha deve ter pelo menos 6 caracteres',
      );
    });

    test('validatePositiveInt deve falhar com zero', () {
      expect(
        FormValidators.validatePositiveInt('0', 'as vagas'),
        'Número inválido',
      );
    });
  });
}