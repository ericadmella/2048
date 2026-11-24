/// Resultado de la consulta de estadísticas globales (COUNT, MAX, AVG, SUM).
class EstadisticasGlobales {
  final int partidasJugadas;
  final int puntuacionMaxima;
  final double puntuacionMedia;
  final int fichaMaxima;
  final int tiempoTotalSegundos;

  const EstadisticasGlobales({
    required this.partidasJugadas,
    required this.puntuacionMaxima,
    required this.puntuacionMedia,
    required this.fichaMaxima,
    required this.tiempoTotalSegundos,
  });

  factory EstadisticasGlobales.fromMap(Map<String, Object?> map) =>
      EstadisticasGlobales(
        partidasJugadas: (map['total'] as int?) ?? 0,
        puntuacionMaxima: (map['max_puntuacion'] as int?) ?? 0,
        puntuacionMedia: ((map['media_puntuacion'] as num?) ?? 0).toDouble(),
        fichaMaxima: (map['max_ficha'] as int?) ?? 0,
        tiempoTotalSegundos: (map['tiempo_total'] as int?) ?? 0,
      );
}

/// Resultado de la consulta agrupada por jugador (GROUP BY).
class EstadisticasJugador {
  final String usuario;
  final int mejorPuntuacion;
  final int partidas;

  const EstadisticasJugador({
    required this.usuario,
    required this.mejorPuntuacion,
    required this.partidas,
  });

  factory EstadisticasJugador.fromMap(Map<String, Object?> map) =>
      EstadisticasJugador(
        usuario: map['usuario'] as String,
        mejorPuntuacion: (map['mejor'] as int?) ?? 0,
        partidas: (map['partidas'] as int?) ?? 0,
      );
}
