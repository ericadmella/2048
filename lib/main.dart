import 'package:flutter/material.dart';

import 'app.dart';
import 'services/ajustes_controller.dart';
import 'services/preferencias_service.dart';

Future<void> main() async {
  // Necesario para usar plugins (shared_preferences, sqflite) antes de runApp.
  WidgetsFlutterBinding.ensureInitialized();

  // Cargamos las preferencias ANTES de runApp para que el primer frame ya se
  // pinte con el tema correcto (sin parpadeo claro -> oscuro).
  final preferencias = await PreferenciasService.cargar();
  final ajustes = AjustesController(preferencias);

  runApp(Game2048App(ajustes: ajustes));
}
