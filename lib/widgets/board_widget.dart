import 'package:flutter/material.dart';

import '../game/game_logic.dart';
import '../theme/app_theme.dart';
import 'tile_widget.dart';

/// Dibuja la cuadrícula del tablero a partir de una lista de valores y
/// reconoce el gesto de deslizar en las cuatro direcciones.
///
/// Se usa `GestureDetector.onPan*` (y no onHorizontalDrag + onVerticalDrag)
/// porque necesitamos comparar los dos ejes para quedarnos con la dirección
/// dominante: si registráramos los dos recognizers por separado competirían
/// en la "gesture arena" y uno de ellos ganaría antes de que el dedo haya
/// recorrido suficiente distancia como para saber la intención real.
class BoardWidget extends StatefulWidget {
  const BoardWidget({
    super.key,
    required this.celdas,
    required this.onSwipe,
    this.tamano = AppSizes.tamanoTablero,
    this.nuevas = const {},
    this.fusionadas = const {},
    this.generacion = 0,
  });

  final List<int> celdas;
  final int tamano;
  final ValueChanged<Direccion> onSwipe;
  final Set<int> nuevas;
  final Set<int> fusionadas;
  final int generacion;

  @override
  State<BoardWidget> createState() => _BoardWidgetState();
}

class _BoardWidgetState extends State<BoardWidget> {
  Offset _desplazamiento = Offset.zero;

  void _onPanStart(DragStartDetails _) => _desplazamiento = Offset.zero;

  void _onPanUpdate(DragUpdateDetails d) => _desplazamiento += d.delta;

  void _onPanEnd(DragEndDetails d) {
    final dir =
        detectarDireccionSwipe(_desplazamiento, d.velocity.pixelsPerSecond);
    _desplazamiento = Offset.zero;
    if (dir != null) widget.onSwipe(dir);
  }

  @override
  Widget build(BuildContext context) {
    final colores = context.tileColors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.separacionFichas),
          decoration: BoxDecoration(
            color: colores.tablero,
            borderRadius: BorderRadius.circular(AppSizes.radioTablero),
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: widget.celdas.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: widget.tamano,
              mainAxisSpacing: AppSizes.separacionFichas,
              crossAxisSpacing: AppSizes.separacionFichas,
            ),
            itemBuilder: (context, i) {
              final valor = widget.celdas[i];
              return Stack(
                children: [
                  // Hueco vacío siempre visible debajo de la ficha.
                  const Positioned.fill(child: TileWidget(valor: 0)),
                  if (valor != 0)
                    Positioned.fill(
                      child: TileWidget(
                        // La clave cambia en cada movimiento para relanzar
                        // las animaciones de aparición/fusión.
                        key: ValueKey('${widget.generacion}-$i-$valor'),
                        valor: valor,
                        esNueva: widget.nuevas.contains(i),
                        esFusion: widget.fusionadas.contains(i),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Devuelve la dirección dominante o `null` si el gesto es demasiado corto.
///
/// Se acepta el swipe si la distancia recorrida supera [AppSizes.umbralSwipe],
/// o si supera la mitad del umbral y además el gesto fue rápido (flick).
/// La dirección es el eje con mayor desplazamiento absoluto.
Direccion? detectarDireccionSwipe(Offset distancia, Offset velocidad) {
  final mayor = distancia.dx.abs() > distancia.dy.abs()
      ? distancia.dx.abs()
      : distancia.dy.abs();
  final esFlick = mayor >= AppSizes.umbralSwipe / 2 &&
      velocidad.distance >= AppSizes.umbralVelocidadSwipe;
  if (mayor < AppSizes.umbralSwipe && !esFlick) return null;

  if (distancia.dx.abs() > distancia.dy.abs()) {
    return distancia.dx > 0 ? Direccion.derecha : Direccion.izquierda;
  } else if (distancia.dy.abs() > distancia.dx.abs()) {
    return distancia.dy > 0 ? Direccion.abajo : Direccion.arriba;
  }
  return null; // diagonal perfecta: ambigua
}
