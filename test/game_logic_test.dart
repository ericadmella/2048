import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:game2048/game/game_controller.dart';
import 'package:game2048/game/game_logic.dart';
import 'package:game2048/models/partida.dart';
import 'package:game2048/models/partida_guardada.dart';
import 'package:game2048/utils/formato.dart';
import 'package:game2048/utils/validadores.dart';
import 'package:game2048/widgets/board_widget.dart';

void main() {
  group('Tablero.mover', () {
    test('fusiona una sola vez por movimiento', () {
      final t = Tablero(celdas: [
        2, 2, 2, 2, //
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
      ]);
      final r = t.mover(Direccion.izquierda);
      expect(t.celdas.sublist(0, 4), [4, 4, 0, 0]);
      expect(r.puntosGanados, 8);
      expect(r.seHaMovido, isTrue);
      expect(r.fusionadas, {0, 1});
    });

    test('desliza hacia la derecha sin huecos', () {
      final t = Tablero(celdas: [
        2, 0, 4, 0, //
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
      ]);
      t.mover(Direccion.derecha);
      expect(t.celdas.sublist(0, 4), [0, 0, 2, 4]);
    });

    test('mueve columnas hacia arriba y abajo', () {
      final t = Tablero(celdas: [
        2, 0, 0, 0, //
        2, 0, 0, 0,
        4, 0, 0, 0,
        4, 0, 0, 0,
      ]);
      t.mover(Direccion.abajo);
      expect(
          [t.celdas[0], t.celdas[4], t.celdas[8], t.celdas[12]], [0, 0, 4, 8]);
      t.mover(Direccion.arriba);
      expect(
          [t.celdas[0], t.celdas[4], t.celdas[8], t.celdas[12]], [4, 8, 0, 0]);
    });

    test('no se mueve si no hay cambios', () {
      final t = Tablero(celdas: [
        2, 4, 0, 0, //
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
      ]);
      expect(t.mover(Direccion.izquierda).seHaMovido, isFalse);
    });

    test('detecta fin de partida', () {
      final t = Tablero(celdas: [
        2, 4, 2, 4, //
        4, 2, 4, 2,
        2, 4, 2, 4,
        4, 2, 4, 2,
      ]);
      expect(t.puedeMover(), isFalse);
      t.celdas[15] = 4;
      expect(t.puedeMover(), isTrue);
    });
  });

  group('GameController', () {
    test('nueva partida empieza con dos fichas', () {
      final c = GameController(random: Random(1))..nuevaPartida();
      expect(c.celdas.where((v) => v != 0).length, 2);
      expect(c.puntuacion, 0);
      expect(c.enCurso, isFalse);
    });

    test('guardar y cargar conserva el estado', () {
      final c = GameController(random: Random(2))..nuevaPartida();
      for (final d in Direccion.values) {
        c.mover(d);
      }
      final g = c.aPartidaGuardada('eric');
      final mapa = g.toMap();
      final recuperada = PartidaGuardada.fromMap(mapa);
      final c2 = GameController()..cargar(recuperada);
      expect(c2.celdas, c.celdas);
      expect(c2.puntuacion, c.puntuacion);
      expect(c2.movimientos, c.movimientos);
      c.dispose();
      c2.dispose();
    });
  });

  test('Partida toMap/fromMap', () {
    final p = Partida(
      id: 3,
      usuario: 'eric',
      puntuacion: 1200,
      fichaMaxima: 128,
      movimientos: 150,
      duracionSegundos: 95,
      fecha: DateTime(2026, 11, 22, 18, 5),
    );
    final p2 = Partida.fromMap(p.toMap());
    expect(p2.id, 3);
    expect(p2.puntuacion, 1200);
    expect(p2.fecha, p.fecha);
    expect(p2.tamanoTablero, 4);
  });

  group('Swipe', () {
    test('ignora desplazamientos cortos', () {
      expect(detectarDireccionSwipe(const Offset(5, 3), Offset.zero), isNull);
    });
    test('elige la dirección dominante', () {
      expect(detectarDireccionSwipe(const Offset(60, 20), Offset.zero),
          Direccion.derecha);
      expect(detectarDireccionSwipe(const Offset(-10, -50), Offset.zero),
          Direccion.arriba);
    });
  });

  test('Validadores y formato', () {
    expect(Validadores.email('sinarroba.com'), isNotNull);
    expect(Validadores.email('eric@correo.com'), isNull);
    expect(Formato.duracion(75), '01:15');
    expect(Formato.duracion(3725), '1:02:05');
  });
}
