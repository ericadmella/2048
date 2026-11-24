import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/partida.dart';
import '../models/partida_guardada.dart';
import 'game_logic.dart';

/// Estado de una partida en curso: tablero, puntuación, movimientos y
/// cronómetro. La pantalla de juego lo escucha (ChangeNotifier) y se encarga
/// de persistirlo a través de los DAOs.
class GameController extends ChangeNotifier {
  GameController({this.tamano = 4, Random? random})
      : _random = random ?? Random() {
    _tablero = Tablero(tamano: tamano, random: _random);
  }

  final int tamano;
  final Random _random;

  late Tablero _tablero;
  int _puntuacion = 0;
  int _movimientos = 0;
  int _segundos = 0;
  bool _terminada = false;
  bool _ganada = false;
  bool _avisoVictoriaMostrado = false;
  Set<int> _nuevas = {};
  Set<int> _fusionadas = {};
  int _generacion = 0;
  Timer? _cronometro;

  List<int> get celdas => List.unmodifiable(_tablero.celdas);
  int get puntuacion => _puntuacion;
  int get movimientos => _movimientos;
  int get segundos => _segundos;
  int get fichaMaxima => _tablero.fichaMaxima;
  bool get terminada => _terminada;
  bool get ganada => _ganada;
  Set<int> get nuevas => _nuevas;
  Set<int> get fusionadas => _fusionadas;

  /// Se incrementa en cada movimiento; los widgets lo usan como clave para
  /// relanzar las animaciones.
  int get generacion => _generacion;

  /// Hay algo que merezca guardarse (se ha movido y no ha terminado).
  bool get enCurso => _movimientos > 0 && !_terminada;

  /// Devuelve `true` solo la primera vez que se alcanza 2048.
  bool consumirAvisoVictoria() {
    if (_ganada && !_avisoVictoriaMostrado) {
      _avisoVictoriaMostrado = true;
      return true;
    }
    return false;
  }

  void nuevaPartida() {
    _tablero = Tablero(tamano: tamano, random: _random);
    final a = _tablero.anadirFichaAleatoria();
    final b = _tablero.anadirFichaAleatoria();
    _puntuacion = 0;
    _movimientos = 0;
    _segundos = 0;
    _terminada = false;
    _ganada = false;
    _avisoVictoriaMostrado = false;
    _nuevas = {if (a != null) a, if (b != null) b};
    _fusionadas = {};
    _generacion++;
    notifyListeners();
  }

  /// Restaura el estado recuperado de la base de datos.
  void cargar(PartidaGuardada guardada) {
    _tablero =
        Tablero(tamano: tamano, random: _random, celdas: guardada.tablero);
    _puntuacion = guardada.puntuacion;
    _movimientos = guardada.movimientos;
    _segundos = guardada.segundosTranscurridos;
    _terminada = !_tablero.puedeMover();
    _ganada = _tablero.fichaMaxima >= 2048;
    _avisoVictoriaMostrado = _ganada;
    _nuevas = {};
    _fusionadas = {};
    _generacion++;
    notifyListeners();
  }

  /// Aplica un movimiento. Devuelve el resultado para que la UI pueda dar
  /// feedback (vibración en fusiones, etc.).
  ResultadoMovimiento mover(Direccion dir) {
    if (_terminada) return ResultadoMovimiento.nulo;
    final r = _tablero.mover(dir);
    if (!r.seHaMovido) return r;

    final nueva = _tablero.anadirFichaAleatoria();
    _puntuacion += r.puntosGanados;
    _movimientos++;
    _nuevas = {if (nueva != null) nueva};
    _fusionadas = r.fusionadas;
    _generacion++;
    if (_tablero.fichaMaxima >= 2048) _ganada = true;
    if (!_tablero.puedeMover()) {
      _terminada = true;
      pausar();
    }
    notifyListeners();
    return r;
  }

  // ------------------------------------------------------------ Cronómetro
  void reanudar() {
    if (_terminada || _cronometro != null) return;
    _cronometro = Timer.periodic(const Duration(seconds: 1), (_) {
      _segundos++;
      notifyListeners();
    });
  }

  void pausar() {
    _cronometro?.cancel();
    _cronometro = null;
  }

  // ---------------------------------------------------------- Conversión
  PartidaGuardada aPartidaGuardada(String usuario) => PartidaGuardada(
        tablero: List.of(_tablero.celdas),
        puntuacion: _puntuacion,
        movimientos: _movimientos,
        segundosTranscurridos: _segundos,
        usuario: usuario,
        tamanoTablero: tamano,
      );

  Partida aPartida({required String usuario, int? usuarioId}) => Partida(
        usuario: usuario,
        usuarioId: usuarioId,
        puntuacion: _puntuacion,
        fichaMaxima: fichaMaxima,
        movimientos: _movimientos,
        duracionSegundos: _segundos,
        fecha: DateTime.now(),
        tamanoTablero: tamano,
      );

  @override
  void dispose() {
    pausar();
    super.dispose();
  }
}
