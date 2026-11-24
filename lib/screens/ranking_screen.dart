import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/cambios_datos.dart';
import '../models/estadisticas.dart';
import '../models/partida.dart';
import '../routes.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/async_data_view.dart';
import '../widgets/empty_state_view.dart';
import '../widgets/partida_list_item.dart';
import '../widgets/stat_card.dart';

/// Datos que necesita la pantalla, cargados en paralelo.
class _DatosRanking {
  const _DatosRanking(this.globales, this.top, this.porJugador);
  final EstadisticasGlobales globales;
  final List<Partida> top;
  final List<EstadisticasJugador> porJugador;
}

/// Top 10, estadísticas globales y estadísticas por jugador.
class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late AppScope _scope;
  Future<_DatosRanking>? _futuro;

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
    super.dispose();
  }

  Future<_DatosRanking> _consultar() async {
    final dao = _scope.partidaDao;
    // Las tres consultas se lanzan en paralelo.
    final r = await Future.wait<Object>([
      dao.estadisticasGlobales(),
      dao.ranking(limite: 10),
      dao.estadisticasPorJugador(),
    ]);
    return _DatosRanking(
      r[0] as EstadisticasGlobales,
      r[1] as List<Partida>,
      r[2] as List<EstadisticasJugador>,
    );
  }

  void _recargar() {
    if (!mounted) return;
    setState(() => _futuro = _consultar());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ranking y estadísticas')),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: AsyncDataView<_DatosRanking>(
          future: _futuro!,
          onReintentar: _recargar,
          desplazable: true,
          esVacio: (d) => d.globales.partidasJugadas == 0,
          vacio: const EmptyStateView(
            icono: Icons.emoji_events_outlined,
            mensaje:
                'Aún no hay partidas.\nJuega una para entrar en el ranking.',
          ),
          builder: (context, d) => _Contenido(datos: d),
        ),
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.datos});

  final _DatosRanking datos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final g = datos.globales;
    final titulo = tema.textTheme.titleLarge;

    final tarjetas = [
      StatCard(
          titulo: 'Partidas jugadas',
          valor: '${g.partidasJugadas}',
          icono: Icons.sports_esports),
      StatCard(
          titulo: 'Puntuación máxima',
          valor: '${g.puntuacionMaxima}',
          icono: Icons.star),
      StatCard(
          titulo: 'Puntuación media',
          valor: Formato.decimal(g.puntuacionMedia),
          icono: Icons.functions),
      StatCard(
          titulo: 'Ficha máxima',
          valor: '${g.fichaMaxima}',
          icono: Icons.grid_view_rounded),
      StatCard(
          titulo: 'Tiempo total',
          valor: Formato.duracion(g.tiempoTotalSegundos),
          icono: Icons.timer_outlined),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.l),
      children: [
        Text('Estadísticas globales', style: titulo),
        const SizedBox(height: AppSpacing.s),
        LayoutBuilder(
          builder: (context, c) {
            final columnas = c.maxWidth > 600 ? 3 : 2;
            final ancho =
                (c.maxWidth - AppSpacing.s * (columnas - 1)) / columnas;
            return Wrap(
              spacing: AppSpacing.s,
              runSpacing: AppSpacing.s,
              children: [
                for (final t in tarjetas) SizedBox(width: ancho, child: t),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Top 10', style: titulo),
        const SizedBox(height: AppSpacing.s),
        for (var i = 0; i < datos.top.length; i++)
          PartidaListItem(
            partida: datos.top[i],
            posicion: i + 1,
            onTap: () => Navigator.pushNamed(
              context,
              AppRoutes.detalle,
              arguments: datos.top[i].id,
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        Text('Por jugador', style: titulo),
        const SizedBox(height: AppSpacing.s),
        Card(
          child: Column(
            children: [
              for (final j in datos.porJugador)
                ListTile(
                  leading: CircleAvatar(
                    child: Text(
                        j.usuario.isEmpty ? '?' : j.usuario[0].toUpperCase()),
                  ),
                  title: Text(j.usuario),
                  subtitle: Text('${j.partidas} partidas'),
                  trailing: Text('${j.mejorPuntuacion}',
                      style: tema.textTheme.titleMedium),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
