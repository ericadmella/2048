import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tarjeta con un título, un valor y un icono para una estadística.
/// Se reutiliza en Ranking/Estadísticas y en el detalle de partida.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.titulo,
    required this.valor,
    required this.icono,
  });

  final String titulo;
  final String valor;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.m),
        child: Row(
          children: [
            Icon(icono,
                size: AppSizes.iconoStat, color: tema.colorScheme.primary),
            const SizedBox(width: AppSpacing.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    titulo,
                    style: tema.textTheme.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    valor,
                    style: AppTextStyles.valorStat
                        .copyWith(color: tema.colorScheme.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
