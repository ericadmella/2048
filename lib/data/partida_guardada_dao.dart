import 'package:sqflite/sqflite.dart';

import '../models/partida_guardada.dart';
import 'cambios_datos.dart';
import 'data_exception.dart';
import 'database_helper.dart';

/// Guardar, recuperar y borrar la partida en curso (tabla `partida_guardada`).
class PartidaGuardadaDao {
  PartidaGuardadaDao({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  static const String _tabla = DatabaseHelper.tablaPartidaGuardada;

  /// Inserta o sustituye la única fila (id = 1).
  Future<void> guardar(PartidaGuardada partida) async {
    try {
      final db = await _helper.database;
      await db.insert(
        _tabla,
        partida.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      CambiosDatos.notificarPartidaGuardada();
    } on DatabaseException catch (e) {
      throw DataException('No se ha podido guardar la partida en curso', e);
    }
  }

  Future<PartidaGuardada?> recuperar() async {
    try {
      final db = await _helper.database;
      final filas = await db.query(
        _tabla,
        where: 'id = ?',
        whereArgs: [PartidaGuardada.idUnico],
        limit: 1,
      );
      return filas.isEmpty ? null : PartidaGuardada.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw DataException('No se ha podido recuperar la partida', e);
    } on FormatException catch (e) {
      // Tablero corrupto: lo descartamos para no bloquear la app.
      await borrar();
      throw DataException(
          'La partida guardada estaba dañada y se ha descartado', e);
    }
  }

  Future<bool> existe() async {
    try {
      final db = await _helper.database;
      final n = Sqflite.firstIntValue(await db.rawQuery(
        'SELECT COUNT(*) FROM $_tabla WHERE id = ?',
        [PartidaGuardada.idUnico],
      ));
      return (n ?? 0) > 0;
    } on DatabaseException catch (e) {
      throw DataException('No se ha podido consultar la partida guardada', e);
    }
  }

  Future<void> borrar() async {
    try {
      final db = await _helper.database;
      await db.delete(
        _tabla,
        where: 'id = ?',
        whereArgs: [PartidaGuardada.idUnico],
      );
      CambiosDatos.notificarPartidaGuardada();
    } on DatabaseException catch (e) {
      throw DataException('No se ha podido borrar la partida guardada', e);
    }
  }
}
