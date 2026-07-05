import 'package:flutter_test/flutter_test.dart';
import 'package:mon_repas_client_mobile/core/utils/validators.dart';

void main() {
  group('validateEmail', () {
    test('email valide → null', () {
      expect(validateEmail('client@mon-repas.com'), isNull);
    });

    test('email invalide ou vide → message', () {
      expect(validateEmail(''), 'Email requis');
      expect(validateEmail(null), 'Email requis');
      expect(validateEmail('pas-un-email'), 'Email invalide');
      expect(validateEmail('a@b'), 'Email invalide');
    });
  });

  group('validatePassword (mêmes règles zod que la webapp : min 8)', () {
    test('8 caractères ou plus → null', () {
      expect(validatePassword('password123'), isNull);
      expect(validatePassword('12345678'), isNull);
    });

    test('trop court ou vide → message', () {
      expect(validatePassword(''), 'Mot de passe requis');
      expect(validatePassword(null), 'Mot de passe requis');
      expect(
        validatePassword('1234567'),
        'Le mot de passe doit contenir au moins 8 caractères',
      );
    });
  });

  group('validateName (prénom/nom min 2)', () {
    test('2 caractères ou plus → null', () {
      expect(validateName('Jo', 'Prénom'), isNull);
    });

    test('trop court ou vide → message', () {
      expect(validateName('', 'Prénom'), 'Prénom requis');
      expect(validateName(null, 'Nom'), 'Nom requis');
      expect(
        validateName('J', 'Prénom'),
        'Prénom doit contenir au moins 2 caractères',
      );
    });
  });

  group('validatePasswordConfirmation', () {
    test('identiques → null', () {
      expect(validatePasswordConfirmation('abcdefgh', 'abcdefgh'), isNull);
    });

    test('différents → message webapp', () {
      expect(
        validatePasswordConfirmation('abcdefgh', 'autre'),
        'Les mots de passe ne correspondent pas',
      );
    });
  });
}
