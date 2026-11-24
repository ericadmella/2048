import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_scope.dart';
import '../data/data_exception.dart';
import '../game/game_controller.dart';
import '../game/game_logic.dart';
import '../services/sesion_service.dart';
import '../theme/app_theme.dart';
import '../utils/formato.dart';
import '../widgets/board_widget.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/score_card.dart';
import '../widgets/tile_widget.dart';

/// Opciones del diálogo que aparece al intentar salir con una partida en curso.
enum _OpcionSalida { guardarYSalir, salirSinGuardar, cancelar }

/// Pantalla de juego: tablero 4×4, puntuación, mejor puntuación,
/// movimientos, cronómetro y botón de reinicio.
///
/// - Guarda la partida al pasar a segundo plano (WidgetsBindingObserver).
/// - Controla el botón «atrás» con PopScope (guardar / no guardar / cancelar).
/// - Al terminar registra la partida en el historial con una transacción.
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.continuar = false});

  /// true: carga la partida guardada en la base de datos.
  final bool continuar;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final GameController _juego = GameController(tamano: AppSizes.tamanoTablero);
  final FocusNode _foco = FocusNode(debugLabel: 'tablero');
  late AppScope _scope;
  bool _iniciado = false;
  bool _cargando = true;
  bool _mostrarDetalles = false;
  int _mejorPrevia = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scope = AppScope.of(context);
    if (!_iniciado) {
      _iniciado = true;
      _iniciar();
    }
  }

  Future<void> _iniciar() async {
    _mejorPrevia = _scope.preferencias.leerMejorPuntuacion();
    if (widget.continuar) {
      try {
        final guardada = await _scope.partidaGuardadaDao.recuperar();
        if (guardada != null) {
          _juego.cargar(guardada);
        } else {
          _juego.nuevaPartida();
          _avisar('No había ninguna partida guardada. Empiezas una nueva.');
        }
      } on DataException catch (e) {
        _juego.nuevaPartida();
        _avisar(e.mensaje);
      }
    } else {
      _juego.nuevaPartida();
    }
    _juego.reanudar();
    if (mounted) setState(() => _cargando = false);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _juego.dispose();
    _foco.dispose();
    super.dispose();
  }

  // ------------------------------------------------- Guardado automático
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _juego.pausar();
        if (_juego.enCurso) _guardar(silencioso: true);
      case AppLifecycleState.resumed:
        _juego.reanudar();
    }
  }

  Future<bool> _guardar({bool silencioso = false}) async {
    try {
      await _scope.partidaGuardadaDao
          .guardar(_juego.aPartidaGuardada(SesionService.instance.nombre));
      if (!silencioso) _avisar('Partida guardada');
      return true;
    } on DataException catch (e) {
      _avisar(e.mensaje);
      return false;
    }
  }

  // ---------------------------------------------------------- Movimientos
  void _mover(Direccion dir) {
    final r = _juego.mover(dir);
    if (!r.seHaMovido) return;
    if (r.fusionadas.isNotEmpty && _scope.ajustes.vibracion) {
      HapticFeedback.lightImpact();
    }
    if (_juego.consumirAvisoVictoria()) {
      _avisar('¡Has llegado a 2048! Puedes seguir jugando.');
    }
    if (_juego.terminada) _finDePartida();
  }

  KeyEventResult _onTecla(FocusNode _, KeyEvent evento) {
    if (evento is! KeyDownEvent) return KeyEventResult.ignored;
    final dir = switch (evento.logicalKey) {
      LogicalKeyboardKey.arrowUp => Direccion.arriba,
      LogicalKeyboardKey.arrowDown => Direccion.abajo,
      LogicalKeyboardKey.arrowLeft => Direccion.izquierda,
      LogicalKeyboardKey.arrowRight => Direccion.derecha,
      _ => null,
    };
    if (dir == null) return KeyEventResult.ignored;
    _mover(dir);
    return KeyEventResult.handled;
  }

  // --------------------------------------------------------- Fin de partida
  Future<void> _finDePartida() async {
    final sesion = SesionService.instance;
    final partida = _juego.aPartida(
      usuario: sesion.nombre,
      usuarioId: sesion.usuario?.id,
    );
    try {
      // Transacción: inserta en `partidas` y borra `partida_guardada`.
      await _scope.partidaDao.registrarPartidaTerminada(partida);
      await _scope.preferencias.actualizarMejorPuntuacion(partida.puntuacion);
    } on DataException catch (e) {
      _avisar(e.mensaje);
    }
    if (!mounted) return;

    final jugarOtra = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Fin de la partida'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TileWidget(
                valor: partida.fichaMaxima, lado: AppSizes.fichaMiniatura),
            const SizedBox(height: AppSpacing.l),
            Text(
              '${partida.puntuacion} puntos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.s),
            Text(
              '${partida.movimientos} movimientos · '
              '${Formato.duracion(partida.duracionSegundos)}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver al inicio'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: Size.zero),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Jugar de nuevo'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (jugarOtra == true) {
      _mejorPrevia = _scope.preferencias.leerMejorPuntuacion();
      _juego.nuevaPartida();
      _juego.reanudar();
    } else {
      Navigator.pop(context);
    }
  }

  // ------------------------------------------------------ Botones de barra
  Future<void> _reiniciar() async {
    if (_juego.enCurso) {
      final ok = await ConfirmDialog.mostrar(
        context,
        titulo: 'Reiniciar partida',
        mensaje: 'Se perderá el progreso de la partida actual.',
        textoConfirmar: 'Reiniciar',
        destructivo: true,
      );
      if (!ok) return;
    }
    try {
      await _scope.partidaGuardadaDao.borrar();
    } on DataException catch (e) {
      _avisar(e.mensaje);
    }
    _juego.nuevaPartida();
    _juego.reanudar();
  }

  // ------------------------------------------------- Botón «atrás» (PopScope)
  Future<void> _confirmarSalida() async {
    final navigator = Navigator.of(context);
    final opcion = await showDialog<_OpcionSalida>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Salir de la partida?'),
        content: const Text('Tienes una partida en curso.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _OpcionSalida.cancelar),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, _OpcionSalida.salirSinGuardar),
            child: const Text('Salir sin guardar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: Size.zero),
            onPressed: () =>
                Navigator.pop(context, _OpcionSalida.guardarYSalir),
            child: const Text('Guardar y salir'),
          ),
        ],
      ),
    );
    switch (opcion) {
      case _OpcionSalida.guardarYSalir:
        _juego.pausar();
        if (await _guardar()) navigator.pop();
      case _OpcionSalida.salirSinGuardar:
        _juego.pausar();
        try {
          await _scope.partidaGuardadaDao.borrar();
        } on DataException catch (e) {
          _avisar(e.mensaje);
        }
        navigator.pop();
      case _OpcionSalida.cancelar:
      case null:
        break;
    }
  }

  void _avisar(String mensaje) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // ------------------------------------------------------------------- UI
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _juego,
      builder: (context, _) => PopScope(
        canPop: !_juego.enCurso,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _confirmarSalida();
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('2048'),
            actions: [
              IconButton(
                tooltip: 'Guardar partida',
                icon: const Icon(Icons.save_outlined),
                onPressed: _juego.enCurso ? () => _guardar() : null,
              ),
              IconButton(
                tooltip: 'Reiniciar',
                icon: const Icon(Icons.refresh),
                onPressed: _cargando ? null : _reiniciar,
              ),
            ],
          ),
          body: _cargando
              ? const Center(child: CircularProgressIndicator())
              : Focus(
                  focusNode: _foco,
                  autofocus: true,
                  onKeyEvent: _onTecla,
                  child: SafeArea(child: _cuerpo()),
                ),
        ),
      ),
    );
  }

  Widget _cuerpo() {
    final mejor =
        _juego.puntuacion > _mejorPrevia ? _juego.puntuacion : _mejorPrevia;
    final marcadores = Wrap(
      alignment: WrapAlignment.center,
      spacing: AppSpacing.s,
      runSpacing: AppSpacing.s,
      children: [
        // Doble toque sobre la puntuación: muestra/oculta los detalles.
        ScoreCard(
          etiqueta: 'Puntos',
          valor: '${_juego.puntuacion}',
          onDoubleTap: () =>
              setState(() => _mostrarDetalles = !_mostrarDetalles),
        ),
        ScoreCard(etiqueta: 'Mejor', valor: '$mejor'),
        ScoreCard(etiqueta: 'Mov.', valor: '${_juego.movimientos}'),
        ScoreCard(etiqueta: 'Tiempo', valor: Formato.duracion(_juego.segundos)),
      ],
    );

    final detalles = AnimatedSize(
      duration: AppSizes.animacionFicha,
      child: _mostrarDetalles
          ? Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s),
              child: Text(
                'Ficha máxima: ${_juego.fichaMaxima} · '
                'Puntos/mov.: ${_juego.movimientos == 0 ? 0 : (_juego.puntuacion / _juego.movimientos).toStringAsFixed(1)}',
                textAlign: TextAlign.center,
              ),
            )
          : const SizedBox(width: double.infinity),
    );

    final tablero = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppSizes.anchoMaximoTablero),
      child: BoardWidget(
        celdas: _juego.celdas,
        tamano: _juego.tamano,
        nuevas: _juego.nuevas,
        fusionadas: _juego.fusionadas,
        generacion: _juego.generacion,
        onSwipe: _mover,
      ),
    );

    final controles = _Cruceta(onMover: _mover);
    final ayuda = Text(
      'Desliza sobre el tablero, usa las flechas del teclado o los botones.\n'
      'Doble toque en «Puntos» para ver más detalles.',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth > constraints.maxHeight;
        if (horizontal) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Row(
              children: [
                Expanded(child: Center(child: tablero)),
                const SizedBox(width: AppSpacing.l),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        marcadores,
                        detalles,
                        const SizedBox(height: AppSpacing.l),
                        controles,
                        const SizedBox(height: AppSpacing.s),
                        ayuda,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.l),
          child: Column(
            children: [
              marcadores,
              detalles,
              const SizedBox(height: AppSpacing.l),
              Expanded(child: Center(child: tablero)),
              const SizedBox(height: AppSpacing.l),
              controles,
              const SizedBox(height: AppSpacing.s),
              ayuda,
            ],
          ),
        );
      },
    );
  }
}

/// Botones de dirección: alternativa accesible al gesto de deslizar.
class _Cruceta extends StatelessWidget {
  const _Cruceta({required this.onMover});

  final ValueChanged<Direccion> onMover;

  @override
  Widget build(BuildContext context) {
    Widget boton(Direccion d, IconData icono, String texto) =>
        IconButton.filledTonal(
          tooltip: texto,
          icon: Icon(icono),
          onPressed: () => onMover(d),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        boton(Direccion.izquierda, Icons.keyboard_arrow_left, 'Izquierda'),
        const SizedBox(width: AppSpacing.s),
        boton(Direccion.arriba, Icons.keyboard_arrow_up, 'Arriba'),
        const SizedBox(width: AppSpacing.s),
        boton(Direccion.abajo, Icons.keyboard_arrow_down, 'Abajo'),
        const SizedBox(width: AppSpacing.s),
        boton(Direccion.derecha, Icons.keyboard_arrow_right, 'Derecha'),
      ],
    );
  }
}
