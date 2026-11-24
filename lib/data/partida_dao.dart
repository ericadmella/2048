import 'package:sqflite/sqflite.dart';

import '../models/estadisticas.dart';
import '../models/partida.dart';
import 'cambios_datos.dart';
import 'data_exception.dart';
import 'database_helper.dart';

/// Encapsula todo el SQL del historial de partidas (tabla `partidas`).
///
/// Todas las consultas usan parámetros (`?` + whereArgs); nunca se
/// concatenan valores introducidos por el usuario en el SQL.
class PartidaDao {
  PartidaDao({DatabaseHelper? helper})
      : _helper = helper ?? DatabaseHelper.instance;

  final DatabaseHelper _helper;

  static const String _tabla = DatabaseHelper.tablaPartidas;
  static const String _tablaGuardada = DatabaseHelper.tablaPartidaGuardada;

  // ---------------------------------------------------------------- CRUD

  /// Inserta una partida terminada y devuelve su id.
  Future<int> insertar(Partida partida) async {
    try {
      final db = await _helper.database;
      final id = await db.insert(_tabla, partida.toMap());
      CambiosDatos.notificarHistorial();
      return id;
    } on DatabaseException catch (e) {
      throw DataException('No se ha podido guardar la partida', e);
    }
  }

  /// Vuelve a insertar una partida borrada conservando su id original
  /// (acción «Deshacer» del SnackBar).
  Future<void> restaurar(Partida partida) async {
    try {
      final db = await _helper.database;
      await db.insert(
        _tabla,
        partida.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      CambiosDatos.notificarHistorial();
    } on DatabaseException catch (e) {
      throw DataException('No se ha podido restaurar la partida', e);
    }
  }

  /// Historial completo ordenado por fecha descendente.
  Future<List<Partida>> obtenerHistorial() => filtrar();

  /// Historial filtrado por nombre de jugador (contiene) y/o ficha mínima.
  Future<List<Partida>> filtrar({String? jugador, int? fichaMinima}) async {
    final condiciones = <String>[];
    final args = <Object?>[];
    if (jugador != null && jugador.trim().isNotEmpty) {
      condiciones.add('usuario LIKE ?');
      args.add('%${jugador.trim()}%');
    }
    if (fichaMinima != null && fichaMinima > 0) {
      condiciones.add('ficha_maxima >= ?');
      args.add(fichaMinima);
    }
    try {
      final db = await _helper.database;
      final filas = await db.query(
        _tabla,
        where: condiciones.isEmpty ? null : condiciones.join(' AND '),
        whereArgs: args.isEmpty ? null : args,
        orderBy: 'fecha DESC',
      );
      return filas.map(Partida.fromMap).toList();
    } on DatabaseException catch (e) {
      throw DataException('No se ha podido cargar el historial', e);
    }
  }

  /// Detalle de una partida por id, o `null` si ya no existe.
  Future<Partida?> obtenerPorId(int id) async {
    try {
      final db = await _helper.database;
      final filas = await db.query(
        _tabla,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      return filas.isEmpty ? null : Partida.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw DataException('No se ha podido cargar la partida', e);
    }
  }

  /// Elimina una partida concreta. Devuelve el número de filas borradas.
  Future<int> eliminar(int id) async {
    try {
      final db = await _helper.database;
      final n = await db.delete(_tabla, where: 'id = ?', whereArgs: [id]);
      CambiosDatos.notificarHistorial();
      return n;
    } on DatabaseException catch (e) {
      throw DataException('No se ha podido eliminar la partida', e);
    }
  }

  /// Elimina todo el historial.
  Future<int> eliminarTodo() async {
    try {
      final db = await _helper.database;
      final n = await db.delete(_tabla);
      CambiosDatos.notificarHistorial();
      return n;
    } on DatabaseException catch (e) {
      throw DataException('No se ha podido borrar el historial', e);
    }
  }

  // --------------------------------------------------------- Transacción

  /// Al terminar una partida: inserta el registro en `partidas` y borra la
  /// fila de `partida_guardada` de forma ATÓMICA. Si algo falla, ninguna de
  /// las dos operaciones se aplica.
  Future<int> registrarPartidaTerminada(Partida partida) async {
    try {
      final db = await _helper.database;
      final id = await db.transaction<int>((txn) async {
        final nuevoId = await txn.insert(_tabla, partida.toMap());
        await txn.delete(_tablaGuardada);
        return nuevoId;
      });
      CambiosDatos.notificarHistorial();
      CambiosDatos.notificarPartidaGuardada();
      return id;
    } on DatabaseException catch (e) {
      throw DataException('No se ha podido registrar la partida', e);
    }
  }

  // ----------------------------------------------- Consultas y agregados

  /// Top 10 por puntuación (ORDER BY + LIMIT).
  Future<List<Partida>> ranking({int limite = 10}) async {
    try {
      final db = await _helper.database;
      final filas = await db.query(
        _tabla,
        orderBy: 'puntuacion DESC, fecha ASC',
        limit: limite,
      );
      return filas.map(Partida.fromMap).toList();
    } on DatabaseException catch (e) {
      throw DataException('No se ha podido cargar el ranking', e);
    }
  }

  /// Estadísticas globales (COUNT, MAX, AVG, SUM).
  Future<EstadisticasGlobales> estadisticasGlobales() async {
    try {
      final db = await _helper.database;
      final filas = await db.rawQuery('''
        SELECT COUNT(*)               AS total,
               MAX(puntuacion)        AS max_puntuacion,
               AVG(puntuacion)        AS media_puntuacion,
               MAX(ficha_maxima)      AS max_ficha,
               SUM(duracion_segundos) AS tiempo_total
        FROM $_tabla
      ''');
      return EstadisticasGlobales.fromMap(filas.first);
    } on DatabaseException catch (e) {
      throw DataException('No se han podido calcular las estadísticas', e);
    }
  }

  /// Mejor puntuación y número de partidas de cada jugador (GROUP BY).
  Future<List<EstadisticasJugador>> estadisticasPorJugador() async {
    try {
      final db = await _helper.database;
      final filas = await db.rawQuery('''
        SELECT usuario,
               MAX(puntuacion) AS mejor,
               COUNT(*)        AS partidas
        FROM $_tabla
        GROUP BY usuario
        ORDER BY mejor DESC
      ''');
      return filas.map(EstadisticasJugador.fromMap).toList();
    } on DatabaseException catch (e) {
      throw DataException('No se han podido calcular las estadísticas', e);
    }
  }

  /// Mejor puntuación de un jugador concreto (0 si no tiene partidas).
  Future<int> mejorPuntuacion({String? usuario}) async {
    try {
      final db = await _helper.database;
      final filas = await db.rawQuery(
        usuario == null
            ? 'SELECT MAX(puntuacion) AS mejor FROM $_tabla'
            : 'SELECT MAX(puntuacion) AS mejor FROM $_tabla WHERE usuario = ?',
        usuario == null ? null : [usuario],
      );
      return (filas.first['mejor'] as int?) ?? 0;
    } on DatabaseException catch (e) {
      throw DataException('No se ha podido leer la mejor puntuación', e);
    }
  }
}
