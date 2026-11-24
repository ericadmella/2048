import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Muestra una etiqueta y un valor numérico (p. ej. «PUNTOS» o «MEJOR»).
/// Se reutiliza en la pantalla de juego y en Inicio.
class ScoreCard extends StatelessWidget {
  const ScoreCard({
    super.key,
    required this.etiqueta,
    required this.valor,
    this.onDoubleTap,
  });

  final String etiqueta;
  final String valor;
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 88),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.l,
          vertical: AppSpacing.s,
        ),
        decoration: BoxDecoration(
          color: esquema.primaryContainer,
          borderRadius: BorderRadius.circular(AppSizes.radioFicha),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              etiqueta.toUpperCase(),
              style: AppTextStyles.etiquetaMarcador
                  .copyWith(color: esquema.onPrimaryContainer),
            ),
            AnimatedSwitcher(
              duration: AppSizes.animacionFicha,
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Text(
                valor,
                key: ValueKey(valor),
                style: AppTextStyles.valorMarcador
                    .copyWith(color: esquema.onPrimaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
