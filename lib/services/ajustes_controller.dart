import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'preferencias_service.dart';

/// Estado de los ajustes de la app (tema, paleta de fichas, vibración).
///
/// Es un [ChangeNotifier]: `MaterialApp` lo escucha con un
/// [ListenableBuilder], de modo que cualquier cambio se refleja al instante
/// en toda la aplicación sin reiniciarla. Cada cambio se persiste en
/// shared_preferences mediante [PreferenciasService].
class AjustesController extends ChangeNotifier {
  AjustesController(this._prefs)
      : _modoTema = _prefs.leerModoTema(),
        _paleta = _prefs.leerPaletaFichas(),
        _vibracion = _prefs.leerVibracion();

  final PreferenciasService _prefs;

  ThemeMode _modoTema;
  PaletaFichas _paleta;
  bool _vibracion;

  ThemeMode get modoTema => _modoTema;
  PaletaFichas get paleta => _paleta;
  bool get vibracion => _vibracion;
  PreferenciasService get preferencias => _prefs;

  Future<void> cambiarModoTema(ThemeMode modo) async {
    if (modo == _modoTema) return;
    _modoTema = modo;
    notifyListeners();
    await _prefs.guardarModoTema(modo);
  }

  Future<void> cambiarPaleta(PaletaFichas paleta) async {
    if (paleta == _paleta) return;
    _paleta = paleta;
    notifyListeners();
    await _prefs.guardarPaletaFichas(paleta);
  }

  Future<void> cambiarVibracion(bool activa) async {
    _vibracion = activa;
    notifyListeners();
    await _prefs.guardarVibracion(activa);
  }
}
