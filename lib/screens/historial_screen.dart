import 'dart:async';

import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/cambios_datos.dart';
import '../data/data_exception.dart';
import '../models/partida.dart';
import '../routes.dart';
import '../theme/app_theme.dart';
import '../widgets/async_data_view.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/partida_list_item.dart';

/// Historial de partidas terminadas con filtros por jugador y ficha máxima.
///
/// Gestos: onTap (detalle), onLongPress (menú), Dismissible (borrar con
/// «Deshacer») y RefreshIndicator (volver a consultar la BD).
class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  static const List<int> _opcionesFicha = [0, 128, 256, 512, 1024, 2048];

  final _filtroCtrl = TextEditingController();
  Timer? _debounce;
  int _fichaMinima = 0;
  late AppScope _scope;
  Future<List<Partida>>? _futuro;

  /// Ids descartados con Dismissible: se ocultan al instante (antes de que
  /// termine el DELETE) para que el widget salga del árbol en ese frame.
  final Set<int> _descartadas = {};

  @override
  void initState() {
    super.initState();
    CambiosDatos.historial.addListener(_recargar);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = AppScope.of(context);
    _futuro ??= _consultar();
  }

  @override
  void dispose() {
    CambiosDatos.historial.removeListener(_recargar);
    _debounce?.cancel();
    _filtroCtrl.dispose();
    super.dispose();
  }

  /// Los filtros llaman al método de consulta del DAO.
  Future<List<Partida>> _consultar() => _scope.partidaDao.filtrar(
        jugador: _filtroCtrl.text,
        fichaMinima: _fichaMinima,
      );

  void _recargar() {
    if (!mounted) return;
    setState(() {
      _descartadas.clear();
      _futuro = _consultar();
    });
  }

  Future<void> _refrescar() async {
    final f = _consultar();
    setState(() => _futuro = f);
    try {
      await f;
    } catch (_) {
      // El error lo muestra AsyncDataView.
    }
  }

  void _onFiltroTexto(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _recargar);
  }

  // --------------------------------------------------------- Navegación
  Future<void> _abrirDetalle(Partida p) async {
    // Se pasa SOLO el id; el detalle consulta la BD.
    final eliminada = await Navigator.pushNamed<bool>(
      context,
      AppRoutes.detalle,
      arguments: p.id,
    );
    if (!mounted) return;
    if (eliminada == true) {
      _recargar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partida eliminada del historial')),
      );
    }
  }

  // ------------------------------------------------------------ Borrado
  /// Borra y ofrece «Deshacer», que vuelve a insertar el registro.
  Future<void> _eliminarConDeshacer(Partida p) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _scope.partidaDao.eliminar(p.id!);
    } on DataException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.mensaje)));
      _recargar();
      return;
    }
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Partida de ${p.puntuacion} puntos eliminada'),
          action: SnackBarAction(
            label: 'Deshacer',
            onPressed: () async {
              try {
                await _scope.partidaDao.restaurar(p);
              } on DataException catch (e) {
                messenger.showSnackBar(SnackBar(content: Text(e.mensaje)));
              }
            },
          ),
        ),
      );
  }

  Future<void> _eliminarConConfirmacion(Partida p) async {
    final ok = await ConfirmDialog.mostrar(
      context,
      titulo: 'Eliminar partida',
      mensaje:
          '¿Seguro que quieres eliminar la partida de ${p.puntuacion} puntos?',
      textoConfirmar: 'Eliminar',
      destructivo: true,
    );
    if (ok) await _eliminarConDeshacer(p);
  }

  void _menuOpciones(Partida p) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text('Ver detalle'),
              onTap: () {
                Navigator.pop(context);
                _abrirDetalle(p);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: const Text('Eliminar'),
              onTap: () {
                Navigator.pop(context);
                _eliminarConConfirmacion(p);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    final hayFiltros = _filtroCtrl.text.trim().isNotEmpty || _fichaMinima > 0;
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.l, AppSpacing.s, AppSpacing.l, AppSpacing.s),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _filtroCtrl,
                    onChanged: _onFiltroTexto,
                    decoration:
                        AppTheme.campo('Jugador', Icons.search).copyWith(
                      isDense: true,
                      suffixIcon: _filtroCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpiar',
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _filtroCtrl.clear();
                                _recargar();
                              },
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.m),
                DropdownButton<int>(
                  value: _fichaMinima,
                  underline: const SizedBox.shrink(),
                  items: [
                    for (final f in _opcionesFicha)
                      DropdownMenuItem(
                        value: f,
                        child: Text(f == 0 ? 'Todas' : '≥ $f'),
                      ),
                  ],
                  onChanged: (v) {
                    _fichaMinima = v ?? 0;
                    _recargar();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refrescar,
              child: AsyncDataView<List<Partida>>(
                future: _futuro!,
                onReintentar: _recargar,
                desplazable: true,
                esVacio: (lista) =>
                    lista.every((p) => _descartadas.contains(p.id)),
                vacio: EmptyStateView(
                  icono: hayFiltros ? Icons.filter_alt_off : Icons.history,
                  mensaje: hayFiltros
                      ? 'Ninguna partida cumple los filtros'
                      : 'Todavía no has terminado ninguna partida',
                ),
                builder: (context, todas) {
                  final partidas =
                      todas.where((p) => !_descartadas.contains(p.id)).toList();
                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.l, vertical: AppSpacing.s),
                    itemCount: partidas.length,
                    itemBuilder: (context, i) {
                      final p = partidas[i];
                      return Dismissible(
                        key: ValueKey('partida-${p.id}'),
                        direction: DismissDirection.endToStart,
                        background: const _FondoBorrar(),
                        onDismissed: (_) {
                          setState(() => _descartadas.add(p.id!));
                          _eliminarConDeshacer(p);
                        },
                        child: PartidaListItem(
                          partida: p,
                          onTap: () => _abrirDetalle(p),
                          onLongPress: () => _menuOpciones(p),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FondoBorrar extends StatelessWidget {
  const _FondoBorrar();

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: esquema.errorContainer,
        borderRadius: BorderRadius.circular(AppSizes.radioTarjeta),
      ),
      child: Icon(Icons.delete, color: esquema.onErrorContainer),
    );
  }
}
