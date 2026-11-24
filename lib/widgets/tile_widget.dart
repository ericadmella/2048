import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Dibuja una ficha del tablero según su valor (color, tamaño y texto).
///
/// Animaciones implícitas:
///  - Ficha nueva: aparece escalando de 0 a 1 (TweenAnimationBuilder).
///  - Fusión: pequeño "pop" (AnimatedScale).
///  - Cambio de valor/color: AnimatedContainer.
class TileWidget extends StatelessWidget {
  const TileWidget({
    super.key,
    required this.valor,
    this.lado,
    this.esNueva = false,
    this.esFusion = false,
  });

  final int valor;

  /// Lado de la ficha. Si es null ocupa todo el espacio disponible.
  final double? lado;
  final bool esNueva;
  final bool esFusion;

  @override
  Widget build(BuildContext context) {
    final colores = context.tileColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final l = lado ?? constraints.biggest.shortestSide;
        Widget ficha = AnimatedContainer(
          duration: AppSizes.animacionFicha,
          width: l,
          height: l,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colores.fondo(valor),
            borderRadius: BorderRadius.circular(AppSizes.radioFicha),
          ),
          child: valor == 0
              ? null
              : FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    child: Text(
                      '$valor',
                      style: AppTextStyles.ficha(valor, l)
                          .copyWith(color: colores.texto(valor)),
                    ),
                  ),
                ),
        );

        if (esFusion) {
          ficha = _Pop(child: ficha);
        }
        if (esNueva) {
          ficha = TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: AppSizes.animacionFicha,
            curve: Curves.easeOutBack,
            builder: (context, escala, child) =>
                Transform.scale(scale: escala, child: child),
            child: ficha,
          );
        }
        return Semantics(
          label: valor == 0 ? 'Celda vacía' : 'Ficha $valor',
          child: ficha,
        );
      },
    );
  }
}

/// Efecto de "pop" al fusionar: escala a 1.15 y vuelve a 1.
class _Pop extends StatefulWidget {
  const _Pop({required this.child});
  final Widget child;

  @override
  State<_Pop> createState() => _PopState();
}

class _PopState extends State<_Pop> {
  double _escala = 1.15;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _escala = 1);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedScale(
        scale: _escala,
        duration: AppSizes.animacionFusion,
        curve: Curves.easeOut,
        child: widget.child,
      );
}
