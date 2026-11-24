import 'dart:convert';

/// Estado de la partida en curso (tabla `partida_guardada`, siempre id = 1).
class PartidaGuardada {
  static const int idUnico = 1;

  final List<int> tablero;
  final int puntuacion;
  final int movimientos;
  final int segundosTranscurridos;
  final String? usuario;
  final int tamanoTablero;

  const PartidaGuardada({
    required this.tablero,
    required this.puntuacion,
    required this.movimientos,
    required this.segundosTranscurridos,
    this.usuario,
    this.tamanoTablero = 4,
  });

  Map<String, Object?> toMap() => {
        'id': idUnico,
        // El tablero se serializa como JSON con la lista de 16 valores.
        'tablero': jsonEncode(tablero),
        'puntuacion': puntuacion,
        'movimientos': movimientos,
        'segundos_transcurridos': segundosTranscurridos,
        'usuario': usuario,
        'tamano_tablero': tamanoTablero,
      };

  factory PartidaGuardada.fromMap(Map<String, Object?> map) => PartidaGuardada(
        tablero: (jsonDecode(map['tablero'] as String) as List)
            .map((e) => e as int)
            .toList(),
        puntuacion: map['puntuacion'] as int,
        movimientos: map['movimientos'] as int,
        segundosTranscurridos: map['segundos_transcurridos'] as int,
        usuario: map['usuario'] as String?,
        tamanoTablero: (map['tamano_tablero'] as int?) ?? 4,
      );
}
