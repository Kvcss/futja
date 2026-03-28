import 'package:flutter_test/flutter_test.dart';
import 'package:futja_app/core/auth_error_mapper.dart';

void main() {
  group('AuthErrorMapper', () {
    test('deve mapear user-not-found', () {
      expect(
        AuthErrorMapper.map('user-not-found'),
        'Usuário não encontrado.',
      );
    });

    test('deve mapear weak-password', () {
      expect(
        AuthErrorMapper.map('weak-password'),
        'Senha muito fraca.',
      );
    });

    test('deve retornar mensagem padrão para erro desconhecido', () {
      expect(
        AuthErrorMapper.map('erro-qualquer'),
        'Falha na autenticação. Tente novamente.',
      );
    });
  });
}