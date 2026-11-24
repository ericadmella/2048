import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Cifrado de contraseñas: SHA-256 con un salt aleatorio por usuario.
///
/// Nunca se guarda la contraseña en claro; solo el hash y el salt.
class PasswordHasher {
  const PasswordHasher();

  static const int _longitudSalt = 16;

  String generarSalt() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(_longitudSalt, (_) => rnd.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String hash(String contrasena, String salt) {
    final bytes = utf8.encode('$salt:$contrasena');
    return sha256.convert(bytes).toString();
  }

  bool verificar(String contrasena, String salt, String hashGuardado) =>
      hash(contrasena, salt) == hashGuardado;
}
