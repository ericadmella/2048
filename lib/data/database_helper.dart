import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Punto único de acceso a la base de datos SQLite `game2048.db`.
///
/// Implementado como singleton: toda la app comparte la misma conexión.
/// Solo los DAOs (carpeta `data/`) usan esta clase; ninguna pantalla
/// accede a [Database] directamente.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();
  factory DatabaseHelper() => instance;

  static const String nombreBaseDatos = 'game2048.db';

  /// Versión actual del esquema.
  ///  - v1: usuarios, partidas, partida_guardada.
  ///  - v2: columna `tamano_tablero` (DEFAULT 4) en partidas y partida_guardada.
  static const int version = 2;

  // Nombres de tablas como constantes para no repetir cadenas.
  static const String tablaUsuarios = 'usuarios';
  static const String tablaPartidas = 'partidas';
  static const String tablaPartidaGuardada = 'partida_guardada';

  Database? _db;

  Future<Database> get database async {
    return _db ??= await _abrir();
  }

  Future<Database> _abrir() async {
    final ruta = join(await getDatabasesPath(), nombreBaseDatos);
    return openDatabase(
      ruta,
      version: version,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Se ejecuta antes de onCreate/onUpgrade: activamos las claves foráneas,
  /// que SQLite trae desactivadas por defecto.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Instalación nueva: se crea el esquema de la v1 y se aplican encima
  /// todas las migraciones hasta [version]. Así una instalación nueva y una
  /// actualizada acaban exactamente con el mismo esquema.
  Future<void> _onCreate(Database db, int version) async {
    await _crearEsquemaV1(db);
    await _migrar(db, 1, version);
  }

  /// Actualización de una versión anterior: se aplican, en orden, solo las
  /// migraciones que faltan. No se borra ninguna tabla, por lo que no se
  /// pierden datos.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _migrar(db, oldVersion, newVersion);
  }

  Future<void> _migrar(Database db, int desde, int hasta) async {
    for (var v = desde + 1; v <= hasta; v++) {
      final migracion = _migraciones[v];
      if (migracion != null) {
        await migracion(db);
      }
    }
  }

  /// Mapa versión -> migración que lleva el esquema a esa versión.
  static final Map<int, Future<void> Function(Database)> _migraciones = {
    2: _migracionV2,
  };

  static Future<void> _crearEsquemaV1(Database db) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE $tablaUsuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario TEXT NOT NULL UNIQUE,
        fecha_registro TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        contrasena TEXT NOT NULL,
        salt TEXT NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE $tablaPartidas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER,
        usuario TEXT NOT NULL,
        puntuacion INTEGER NOT NULL,
        ficha_maxima INTEGER NOT NULL,
        movimientos INTEGER NOT NULL,
        duracion_segundos INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES $tablaUsuarios (id)
          ON DELETE CASCADE
      )
    ''');
    batch.execute('''
      CREATE TABLE $tablaPartidaGuardada (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        tablero TEXT NOT NULL,
        puntuacion INTEGER NOT NULL,
        movimientos INTEGER NOT NULL,
        segundos_transcurridos INTEGER NOT NULL,
        usuario TEXT
      )
    ''');
    // Índices para acelerar ranking y filtros del historial.
    batch.execute(
        'CREATE INDEX idx_partidas_puntuacion ON $tablaPartidas (puntuacion DESC)');
    batch.execute(
        'CREATE INDEX idx_partidas_usuario ON $tablaPartidas (usuario)');
    await batch.commit(noResult: true);
  }

  /// v1 -> v2: añade `tamano_tablero` con valor por defecto 4.
  /// ALTER TABLE ... ADD COLUMN conserva todas las filas existentes, que
  /// reciben el valor por defecto.
  static Future<void> _migracionV2(Database db) async {
    await db.execute(
        'ALTER TABLE $tablaPartidas ADD COLUMN tamano_tablero INTEGER NOT NULL DEFAULT 4');
    await db.execute(
        'ALTER TABLE $tablaPartidaGuardada ADD COLUMN tamano_tablero INTEGER NOT NULL DEFAULT 4');
  }

  Future<void> cerrar() async {
    final db = _db;
    if (db != null && db.isOpen) {
      await db.close();
    }
    _db = null;
  }
}
