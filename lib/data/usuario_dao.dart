import 'package:sqflite/sqflite.dart';

import '../models/usuario.dart';
import '../services/password_hasher.dart';
import 'data_exception.dart';
import 'database_helper.dart';

/// Operaciones SQL sobre la tabla `usuarios`.
class UsuarioDao {
  UsuarioDao({DatabaseHelper? helper, PasswordHasher? hasher})
      : _helper = helper ?? DatabaseHelper.instance,
        _hasher = hasher ?? const PasswordHasher();

  final DatabaseHelper _helper;
  final PasswordHasher _hasher;

  static const String _tabla = DatabaseHelper.tablaUsuarios;

  /// Registra un usuario nuevo. Lanza [DataException] si el nombre o el
  /// email ya existen.
  Future<Usuario> registrar({
    required String usuario,
    required String email,
    required String contrasena,
  }) async {
    final db = await _helper.database;
    final salt = _hasher.generarSalt();
    final nuevo = Usuario(
      usuario: usuario.trim(),
      email: email.trim().toLowerCase(),
      fechaRegistro: DateTime.now(),
      contrasenaHash: _hasher.hash(contrasena, salt),
      salt: salt,
    );
    try {
      final id = await db.insert(
        _tabla,
        nuevo.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return Usuario.fromMap({...nuevo.toMap(), 'id': id});
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        throw DataException(
            'Ese nombre de usuario o email ya está registrado', e);
      }
      throw DataException('No se ha podido registrar el usuario', e);
    }
  }

  /// Devuelve el usuario si las credenciales son correctas, o `null`.
  Future<Usuario?> autenticar(String usuario, String contrasena) async {
    final encontrado = await buscarPorNombre(usuario);
    if (encontrado == null) return null;
    final ok = _hasher.verificar(
      contrasena,
      encontrado.salt,
      encontrado.contrasenaHash,
    );
    return ok ? encontrado : null;
  }

  Future<Usuario?> buscarPorNombre(String usuario) async {
    try {
      final db = await _helper.database;
      final filas = await db.query(
        _tabla,
        where: 'usuario = ?',
        whereArgs: [usuario.trim()],
        limit: 1,
      );
      return filas.isEmpty ? null : Usuario.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw DataException('Error al buscar el usuario', e);
    }
  }
}
