import 'package:flutter/material.dart';

import 'screens/detalle_partida_screen.dart';
import 'screens/game_screen.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

/// Sistema de rutas centralizado: TODA la navegación de la app usa estas
/// rutas con nombre (Navigator.pushNamed). No hay MaterialPageRoute
/// dispersos por las pantallas.
class AppRoutes {
  AppRoutes._();

  static const String login = '/login';
  static const String registro = '/registro';
  static const String inicio = '/';
  static const String juego = '/juego';
  static const String detalle = '/detalle';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _ruta(settings, const LoginScreen());
      case registro:
        return _ruta(settings, const RegisterScreen());
      case inicio:
        return _ruta(settings, const HomeShell());
      case juego:
        // Argumento: JuegoArgs (continuar o nueva partida).
        final args = settings.arguments as JuegoArgs? ?? const JuegoArgs();
        return _ruta(settings, GameScreen(continuar: args.continuar));
      case detalle:
        // Argumento: solo el id de la partida. La pantalla de detalle
        // consulta la base de datos con ese id.
        final id = settings.arguments as int;
        return _ruta<bool>(settings, DetallePartidaScreen(partidaId: id));
      default:
        return _ruta(
          settings,
          const Scaffold(body: Center(child: Text('Ruta no encontrada'))),
        );
    }
  }

  static MaterialPageRoute<T> _ruta<T>(
          RouteSettings settings, Widget pantalla) =>
      MaterialPageRoute<T>(settings: settings, builder: (_) => pantalla);
}

/// Argumentos de la ruta [AppRoutes.juego].
class JuegoArgs {
  const JuegoArgs({this.continuar = false});
  final bool continuar;
}
