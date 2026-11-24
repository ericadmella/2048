import 'package:flutter/widgets.dart';

import 'data/partida_dao.dart';
import 'data/partida_guardada_dao.dart';
import 'data/usuario_dao.dart';
import 'services/ajustes_controller.dart';
import 'services/preferencias_service.dart';

/// Inyección de dependencias sencilla: las pantallas obtienen los DAOs y el
/// controlador de ajustes con `AppScope.of(context)`. Los widgets
/// reutilizables NO lo usan: reciben datos y callbacks por constructor.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.ajustes,
    required this.partidaDao,
    required this.partidaGuardadaDao,
    required this.usuarioDao,
    required super.child,
  });

  final AjustesController ajustes;
  final PartidaDao partidaDao;
  final PartidaGuardadaDao partidaGuardadaDao;
  final UsuarioDao usuarioDao;

  PreferenciasService get preferencias => ajustes.preferencias;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No hay un AppScope por encima en el árbol');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      ajustes != oldWidget.ajustes ||
      partidaDao != oldWidget.partidaDao ||
      partidaGuardadaDao != oldWidget.partidaGuardadaDao ||
      usuarioDao != oldWidget.usuarioDao;
}
