/// Usuario registrado en la aplicación (tabla `usuarios`).
class Usuario {
  final int? id;
  final String usuario;
  final DateTime fechaRegistro;
  final String email;

  /// Hash SHA-256 de (salt + contraseña). Nunca se guarda la contraseña en claro.
  final String contrasenaHash;
  final String salt;

  const Usuario({
    this.id,
    required this.usuario,
    required this.fechaRegistro,
    required this.email,
    required this.contrasenaHash,
    required this.salt,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'usuario': usuario,
        'fecha_registro': fechaRegistro.toIso8601String(),
        'email': email,
        'contrasena': contrasenaHash,
        'salt': salt,
      };

  factory Usuario.fromMap(Map<String, Object?> map) => Usuario(
        id: map['id'] as int?,
        usuario: map['usuario'] as String,
        fechaRegistro: DateTime.parse(map['fecha_registro'] as String),
        email: map['email'] as String,
        contrasenaHash: map['contrasena'] as String,
        salt: map['salt'] as String,
      );
}
