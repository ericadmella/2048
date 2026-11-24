import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Mensaje e icono para cuando no hay datos que mostrar.
/// Se reutiliza en Historial, Ranking y en filtros sin resultados.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.mensaje,
    this.icono = Icons.inbox_outlined,
    this.accion,
  });

  final String mensaje;
  final IconData icono;

  /// Botón opcional bajo el mensaje (p. ej. «Reintentar» o «Jugar»).
  final Widget? accion;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icono,
                size: AppSizes.iconoEstado, color: tema.colorScheme.outline),
            const SizedBox(height: AppSpacing.l),
            Text(
              mensaje,
              style: tema.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (accion != null) ...[
              const SizedBox(height: AppSpacing.l),
              accion!,
            ],
          ],
        ),
      ),
    );
  }
}
