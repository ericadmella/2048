import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/data_exception.dart';
import '../models/partida.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/async_data_view.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/stat_card.dart';
import '../widgets/tile_widget.dart';

/// Detalle de una partida. Recibe SOLO el id y consulta la base de datos.
/// Si se elimina, vuelve con `Navigator.pop(context, true)` para que el
/// historial se actualice.
class DetallePartidaScreen extends StatefulWidget {
  const DetallePartidaScreen({super.key, required this.partidaId});

  final int partidaId;

  @override
  State<DetallePartidaScreen> createState() => _DetallePartidaScreenState();
}

class _DetallePartidaScreenState extends State<DetallePartidaScreen> {
  late AppScope _scope;
  Future<Partida?>? _futuro;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = AppScope.of(context);
    _futuro ??= _scope.partidaDao.obtenerPorId(widget.partidaId);
  }

  void _recargar() => setState(
      () => _futuro = _scope.partidaDao.obtenerPorId(widget.partidaId));

  Future<void> _eliminar() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ConfirmDialog.mostrar(
      context,
      titulo: 'Eliminar partida',
      mensaje: 'Esta acción no se puede deshacer.',
      textoConfirmar: 'Eliminar',
      destructivo: true,
    );
    if (!ok) return;
    try {
      await _scope.partidaDao.eliminar(widget.partidaId);
      // Devolvemos el resultado a la pantalla anterior.
      navigator.pop(true);
    } on DataException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Partida #${widget.partidaId}'),
        actions: [
          IconButton(
            tooltip: 'Eliminar',
            icon: const Icon(Icons.delete_outline),
            onPressed: _eliminar,
          ),
        ],
      ),
      body: AsyncDataView<Partida?>(
        future: _futuro!,
        onReintentar: _recargar,
        esVacio: (p) => p == null,
        vacio: const EmptyStateView(
          icono: Icons.search_off,
          mensaje: 'Esta partida ya no existe',
        ),
        builder: (context, p) => _Contenido(partida: p!),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.partida});

  final Partida partida;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.l),
      children: [
        Center(
          child: TileWidget(
            valor: partida.fichaMaxima,
            lado: AppSizes.fichaMiniatura * 2,
          ),
        ),
        const SizedBox(height: AppSpacing.l),
        Text(
          partida.usuario,
          textAlign: TextAlign.center,
          style: tema.textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.l),
        StatCard(
          titulo: 'Puntuación',
          valor: '${partida.puntuacion}',
          icono: Icons.star,
        ),
        StatCard(
          titulo: 'Ficha máxima',
          valor: '${partida.fichaMaxima}',
          icono: Icons.grid_view_rounded,
        ),
        StatCard(
          titulo: 'Movimientos',
          valor: '${partida.movimientos}',
          icono: Icons.swipe,
        ),
        StatCard(
          titulo: 'Duración',
          valor: Formato.duracion(partida.duracionSegundos),
          icono: Icons.timer_outlined,
        ),
        StatCard(
          titulo: 'Fecha',
          valor: Formato.fecha(partida.fecha),
          icono: Icons.calendar_today,
        ),
        StatCard(
          titulo: 'Tablero',
          valor: '${partida.tamanoTablero}×${partida.tamanoTablero}',
          icono: Icons.border_all,
        ),
      ],
    );
  }
}
