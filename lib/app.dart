import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'data/partida_dao.dart';
import 'data/partida_guardada_dao.dart';
import 'data/usuario_dao.dart';
import 'routes.dart';
import 'services/ajustes_controller.dart';
import 'theme/app_theme.dart';

class Game2048App extends StatelessWidget {
  Game2048App({
    super.key,
    required this.ajustes,
    PartidaDao? partidaDao,
    PartidaGuardadaDao? partidaGuardadaDao,
    UsuarioDao? usuarioDao,
  })  : partidaDao = partidaDao ?? PartidaDao(),
        partidaGuardadaDao = partidaGuardadaDao ?? PartidaGuardadaDao(),
        usuarioDao = usuarioDao ?? UsuarioDao();

  final AjustesController ajustes;
  final PartidaDao partidaDao;
  final PartidaGuardadaDao partidaGuardadaDao;
  final UsuarioDao usuarioDao;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      ajustes: ajustes,
      partidaDao: partidaDao,
      partidaGuardadaDao: partidaGuardadaDao,
      usuarioDao: usuarioDao,
      // ListenableBuilder reconstruye MaterialApp cada vez que cambian los
      // ajustes: el tema se aplica en tiempo real en toda la app.
      child: ListenableBuilder(
        listenable: ajustes,
        builder: (context, _) => MaterialApp(
          title: '2048',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.claro(ajustes.paleta),
          darkTheme: AppTheme.oscuro(ajustes.paleta),
          themeMode: ajustes.modoTema,
          initialRoute: AppRoutes.login,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
      ),
    );
  }
}
