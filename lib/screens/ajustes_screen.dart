import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/data_exception.dart';
import '../routes.dart';
import '../services/sesion_service.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/tile_widget.dart';

/// Ajustes: modo de tema (claro/oscuro/sistema), paleta de colores de las
/// fichas, vibración, borrar historial y cerrar sesión.
class AjustesScreen extends StatelessWidget {
  const AjustesScreen({super.key});

  Future<void> _borrarHistorial(BuildContext context) async {
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ConfirmDialog.mostrar(
      context,
      titulo: 'Borrar historial',
      mensaje: 'Se eliminarán TODAS las partidas del historial. '
          'Esta acción no se puede deshacer.',
      textoConfirmar: 'Borrar todo',
      destructivo: true,
    );
    if (!ok) return;
    try {
      final n = await scope.partidaDao.eliminarTodo();
      await scope.preferencias.guardarMejorPuntuacion(0);
      messenger.showSnackBar(
          SnackBar(content: Text('Historial borrado ($n partidas)')));
    } on DataException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.mensaje)));
    }
  }

  Future<void> _cerrarSesion(BuildContext context) async {
    final navigator = Navigator.of(context);
    final ok = await ConfirmDialog.mostrar(
      context,
      titulo: 'Cerrar sesión',
      mensaje: '¿Quieres cerrar la sesión de ${SesionService.instance.nombre}?',
      textoConfirmar: 'Cerrar sesión',
    );
    if (!ok) return;
    SesionService.instance.cerrar();
    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final ajustes = AppScope.of(context).ajustes;
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListenableBuilder(
        listenable: ajustes,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(AppSpacing.l),
          children: [
            Text('Tema', style: tema.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode),
                  label: Text('Claro'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode),
                  label: Text('Oscuro'),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('Sistema'),
                ),
              ],
              selected: {ajustes.modoTema},
              onSelectionChanged: (s) => ajustes.cambiarModoTema(s.first),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Color de las fichas', style: tema.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s),
            for (final p in PaletaFichas.values)
              _OpcionPaleta(
                paleta: p,
                seleccionada: ajustes.paleta == p,
                onSeleccionar: () => ajustes.cambiarPaleta(p),
              ),
            const SizedBox(height: AppSpacing.l),
            SwitchListTile(
              title: const Text('Vibración al fusionar fichas'),
              secondary: const Icon(Icons.vibration),
              value: ajustes.vibracion,
              onChanged: ajustes.cambiarVibracion,
            ),
            const Divider(height: AppSpacing.xxl),
            ListTile(
              leading:
                  Icon(Icons.delete_forever, color: tema.colorScheme.error),
              title: const Text('Borrar todo el historial'),
              onTap: () => _borrarHistorial(context),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Cerrar sesión'),
              subtitle: Text(SesionService.instance.nombre),
              onTap: () => _cerrarSesion(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila para elegir una paleta, con una vista previa de sus fichas.
/// La vista previa usa el tema de esa paleta (no el activo) para que se vea
/// cómo quedaría.
class _OpcionPaleta extends StatelessWidget {
  const _OpcionPaleta({
    required this.paleta,
    required this.seleccionada,
    required this.onSeleccionar,
  });

  final PaletaFichas paleta;
  final bool seleccionada;
  final VoidCallback onSeleccionar;

  static const List<int> _muestra = [2, 8, 64, 512, 2048];

  @override
  Widget build(BuildContext context) {
    final brillo = Theme.of(context).brightness;
    final temaPaleta = brillo == Brightness.dark
        ? AppTheme.oscuro(paleta)
        : AppTheme.claro(paleta);
    return Card(
      shape: seleccionada
          ? RoundedRectangleBorder(
              side: BorderSide(
                  color: Theme.of(context).colorScheme.primary, width: 2),
              borderRadius: BorderRadius.circular(AppSizes.radioTarjeta),
            )
          : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.radioTarjeta),
        onTap: onSeleccionar,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.m),
          child: Row(
            children: [
              Icon(seleccionada
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off),
              const SizedBox(width: AppSpacing.m),
              Expanded(child: Text(paleta.etiqueta)),
              Theme(
                data: temaPaleta,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final v in _muestra)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xs),
                        child: TileWidget(
                            valor: v, lado: AppSizes.fichaMiniatura * 0.55),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
