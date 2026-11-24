import 'package:flutter/foundation.dart';

/// Notificador global de cambios en el historial de partidas.
///
/// Los DAOs lo incrementan tras cada escritura (insertar, borrar,
/// deshacer, terminar partida) y las pantallas que muestran listas o
/// estadísticas lo escuchan para volver a consultar la base de datos sin
/// reiniciar la aplicación.
class CambiosDatos {
  CambiosDatos._();

  static final ValueNotifier<int> historial = ValueNotifier<int>(0);
  static final ValueNotifier<int> partidaGuardada = ValueNotifier<int>(0);

  static void notificarHistorial() => historial.value++;
  static void notificarPartidaGuardada() => partidaGuardada.value++;
}
