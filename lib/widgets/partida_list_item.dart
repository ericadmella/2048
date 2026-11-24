import 'package:flutter/material.dart';

import '../models/partida.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import 'tile_widget.dart';

/// Elemento de lista con los datos resumidos de una partida.
/// Se reutiliza en Historial y en Ranking.
class PartidaListItem extends StatelessWidget {
  const PartidaListItem({
    super.key,
    required this.partida,
    this.posicion,
    this.onTap,
    this.onLongPress,
  });

  final Partida partida;

  /// Posición en el ranking (1..10). Si es null no se muestra.
  final int? posicion;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (posicion != null)
              SizedBox(
                width: AppSpacing.xxl,
                child: Text(
                  '#$posicion',
                  style: tema.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            TileWidget(
              valor: partida.fichaMaxima,
              lado: AppSizes.fichaMiniatura * 0.75,
            ),
          ],
        ),
        title: Text(
          '${partida.puntuacion} puntos',
          style: tema.textTheme.titleMedium,
        ),
        subtitle: Text(
          '${partida.usuario} · ${partida.movimientos} mov. · '
          '${Formato.duracion(partida.duracionSegundos)}\n'
          '${Formato.fecha(partida.fecha)}',
        ),
        isThreeLine: true,
        trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      ),
    );
  }
}
