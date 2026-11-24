import 'dart:math';

/// Dirección de un movimiento del tablero.
enum Direccion { arriba, abajo, izquierda, derecha }

/// Resultado de aplicar un movimiento.
class ResultadoMovimiento {
  const ResultadoMovimiento({
    required this.seHaMovido,
    required this.puntosGanados,
    required this.fusionadas,
  });

  final bool seHaMovido;
  final int puntosGanados;

  /// Índices (0..15) de las celdas donde se ha producido una fusión.
  final Set<int> fusionadas;

  static const ResultadoMovimiento nulo =
      ResultadoMovimiento(seHaMovido: false, puntosGanados: 0, fusionadas: {});
}

/// Lógica pura del 2048 (sin Flutter), fácil de probar con tests unitarios.
///
/// El tablero se representa como una lista de `tamano * tamano` enteros, por
/// filas; 0 significa celda vacía.
class Tablero {
  Tablero({this.tamano = 4, Random? random, List<int>? celdas})
      : _random = random ?? Random(),
        celdas = celdas != null
            ? List<int>.of(celdas)
            : List<int>.filled(tamano * tamano, 0) {
    assert(this.celdas.length == tamano * tamano);
  }

  final int tamano;
  final Random _random;
  final List<int> celdas;

  int get fichaMaxima => celdas.fold(0, max);

  List<int> get vacias => [
        for (var i = 0; i < celdas.length; i++)
          if (celdas[i] == 0) i,
      ];

  /// Coloca una ficha nueva (2 con 90 % de probabilidad, 4 con 10 %) en una
  /// celda vacía aleatoria. Devuelve su índice o `null` si no hay hueco.
  int? anadirFichaAleatoria() {
    final libres = vacias;
    if (libres.isEmpty) return null;
    final indice = libres[_random.nextInt(libres.length)];
    celdas[indice] = _random.nextDouble() < 0.9 ? 2 : 4;
    return indice;
  }

  /// Aplica un movimiento en la dirección indicada.
  ResultadoMovimiento mover(Direccion dir) {
    var seHaMovido = false;
    var puntos = 0;
    final fusionadas = <int>{};

    for (var linea = 0; linea < tamano; linea++) {
      final indices = _indicesLinea(linea, dir);
      final valores = [for (final i in indices) celdas[i]];
      final (nuevos, ganados, posFusion) = _comprimir(valores);
      for (var k = 0; k < tamano; k++) {
        if (celdas[indices[k]] != nuevos[k]) seHaMovido = true;
        celdas[indices[k]] = nuevos[k];
      }
      puntos += ganados;
      fusionadas.addAll(posFusion.map((k) => indices[k]));
    }

    return ResultadoMovimiento(
      seHaMovido: seHaMovido,
      puntosGanados: puntos,
      fusionadas: fusionadas,
    );
  }

  /// `true` si queda algún movimiento posible.
  bool puedeMover() {
    if (celdas.contains(0)) return true;
    for (var f = 0; f < tamano; f++) {
      for (var c = 0; c < tamano; c++) {
        final v = celdas[f * tamano + c];
        if (c + 1 < tamano && celdas[f * tamano + c + 1] == v) return true;
        if (f + 1 < tamano && celdas[(f + 1) * tamano + c] == v) return true;
      }
    }
    return false;
  }

  /// Índices de una fila/columna ordenados en el sentido del movimiento
  /// (la primera posición es hacia donde se desplazan las fichas).
  List<int> _indicesLinea(int linea, Direccion dir) {
    return switch (dir) {
      Direccion.izquierda => [
          for (var c = 0; c < tamano; c++) linea * tamano + c
        ],
      Direccion.derecha => [
          for (var c = tamano - 1; c >= 0; c--) linea * tamano + c
        ],
      Direccion.arriba => [for (var f = 0; f < tamano; f++) f * tamano + linea],
      Direccion.abajo => [
          for (var f = tamano - 1; f >= 0; f--) f * tamano + linea
        ],
    };
  }

  /// Desliza y fusiona una línea hacia la posición 0.
  /// Cada ficha solo puede fusionarse una vez por movimiento.
  (List<int>, int, List<int>) _comprimir(List<int> linea) {
    final sinCeros = linea.where((v) => v != 0).toList();
    final resultado = <int>[];
    final posFusion = <int>[];
    var puntos = 0;
    var i = 0;
    while (i < sinCeros.length) {
      if (i + 1 < sinCeros.length && sinCeros[i] == sinCeros[i + 1]) {
        final suma = sinCeros[i] * 2;
        posFusion.add(resultado.length);
        resultado.add(suma);
        puntos += suma;
        i += 2;
      } else {
        resultado.add(sinCeros[i]);
        i++;
      }
    }
    while (resultado.length < linea.length) {
      resultado.add(0);
    }
    return (resultado, puntos, posFusion);
  }
}
