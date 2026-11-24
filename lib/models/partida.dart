/// Partida terminada guardada en el historial (tabla `partidas`).
class Partida {
  final int? id;
  final int? usuarioId;
  final String usuario;
  final int puntuacion;
  final int fichaMaxima;
  final int movimientos;
  final int duracionSegundos;
  final DateTime fecha;

  /// Columna añadida en la versión 2 de la base de datos.
  final int tamanoTablero;

  const Partida({
    this.id,
    this.usuarioId,
    required this.usuario,
    required this.puntuacion,
    required this.fichaMaxima,
    required this.movimientos,
    required this.duracionSegundos,
    required this.fecha,
    this.tamanoTablero = 4,
  });

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'usuario_id': usuarioId,
        'usuario': usuario,
        'puntuacion': puntuacion,
        'ficha_maxima': fichaMaxima,
        'movimientos': movimientos,
        'duracion_segundos': duracionSegundos,
        'fecha': fecha.toIso8601String(),
        'tamano_tablero': tamanoTablero,
      };

  factory Partida.fromMap(Map<String, Object?> map) => Partida(
        id: map['id'] as int?,
        usuarioId: map['usuario_id'] as int?,
        usuario: map['usuario'] as String,
        puntuacion: map['puntuacion'] as int,
        fichaMaxima: map['ficha_maxima'] as int,
        movimientos: map['movimientos'] as int,
        duracionSegundos: map['duracion_segundos'] as int,
        fecha: DateTime.parse(map['fecha'] as String),
        tamanoTablero: (map['tamano_tablero'] as int?) ?? 4,
      );
}
