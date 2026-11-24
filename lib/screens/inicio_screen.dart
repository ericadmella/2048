import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/cambios_datos.dart';
import '../data/data_exception.dart';
import '../routes.dart';
import '../services/sesion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/score_card.dart';
import 'home_shell.dart';

/// Pantalla de inicio: nombre del juego, mejor puntuación y accesos a
/// nueva partida, continuar (solo si hay una guardada), historial, ranking
/// y ajustes.
class InicioScreen extends StatefulWidget {
  const InicioScreen({super.key, required this.onIrAPestana});

  final ValueChanged<int> onIrAPestana;

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  bool _hayGuardada = false;
  int _mejor = 0;
  bool _cargado = false;
  late AppScope _scope;

  @override
  void initState() {
    super.initState();
    CambiosDatos.partidaGuardada.addListener(_cargar);
    CambiosDatos.historial.addListener(_cargar);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = AppScope.of(context);
    if (!_cargado) {
      _cargado = true;
      // Valor rápido desde shared_preferences mientras consultamos la BD.
      _mejor = _scope.preferencias.leerMejorPuntuacion();
      _cargar();
    }
  }

  @override
  void dispose() {
    CambiosDatos.partidaGuardada.removeListener(_cargar);
    CambiosDatos.historial.removeListener(_cargar);
    super.dispose();
  }

  Future<void> _cargar() async {
    final scope = _scope;
    try {
      final hay = await scope.partidaGuardadaDao.existe();
      final mejor = await scope.partidaDao.mejorPuntuacion();
      await scope.preferencias.guardarMejorPuntuacion(mejor);
      if (!mounted) return;
      setState(() {
        _hayGuardada = hay;
        _mejor = mejor;
      });
    } on DataException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  Future<void> _nuevaPartida() async {
    final scope = _scope;
    final navigator = Navigator.of(context);
    if (_hayGuardada) {
      final ok = await ConfirmDialog.mostrar(
        context,
        titulo: 'Nueva partida',
        mensaje:
            'Tienes una partida guardada. Si empiezas una nueva se descartará.',
        textoConfirmar: 'Empezar nueva',
        destructivo: true,
      );
      if (!ok) return;
      await scope.partidaGuardadaDao.borrar();
    }
    await navigator.pushNamed(AppRoutes.juego, arguments: const JuegoArgs());
    _cargar();
  }

  Future<void> _continuar() async {
    await Navigator.pushNamed(
      context,
      AppRoutes.juego,
      arguments: const JuegoArgs(continuar: true),
    );
    _cargar();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final sesion = SesionService.instance;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AppSizes.anchoMaximoFormulario),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '2048',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.tituloJuego
                      .copyWith(color: tema.colorScheme.primary),
                ),
                Text(
                  'Hola, ${sesion.nombre}',
                  textAlign: TextAlign.center,
                  style: tema.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.l),
                Center(child: ScoreCard(etiqueta: 'Mejor', valor: '$_mejor')),
                const SizedBox(height: AppSpacing.xl),
                if (_hayGuardada) ...[
                  Card(
                    color: tema.colorScheme.secondaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: Text(
                        'Tienes una partida a medias. ¿Quieres continuarla o empezar una nueva?',
                        style: tema.textTheme.bodyLarge?.copyWith(
                          color: tema.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.m),
                  FilledButton.icon(
                    onPressed: _continuar,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Continuar partida'),
                  ),
                  const SizedBox(height: AppSpacing.m),
                ],
                _hayGuardada
                    ? OutlinedButton.icon(
                        onPressed: _nuevaPartida,
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva partida'),
                      )
                    : FilledButton.icon(
                        onPressed: _nuevaPartida,
                        icon: const Icon(Icons.add),
                        label: const Text('Nueva partida'),
                      ),
                const SizedBox(height: AppSpacing.m),
                OutlinedButton.icon(
                  onPressed: () => widget.onIrAPestana(Pestanas.historial),
                  icon: const Icon(Icons.history),
                  label: const Text('Historial'),
                ),
                const SizedBox(height: AppSpacing.m),
                OutlinedButton.icon(
                  onPressed: () => widget.onIrAPestana(Pestanas.ranking),
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('Ranking'),
                ),
                const SizedBox(height: AppSpacing.m),
                OutlinedButton.icon(
                  onPressed: () => widget.onIrAPestana(Pestanas.ajustes),
                  icon: const Icon(Icons.settings),
                  label: const Text('Ajustes'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
