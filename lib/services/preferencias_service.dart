import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';

/// Encapsula todo el acceso a [SharedPreferences].
///
/// Ninguna otra clase usa SharedPreferences directamente, y todas las claves
/// están definidas como constantes aquí.
class PreferenciasService {
  PreferenciasService._(this._prefs);

  final SharedPreferences _prefs;

  // ----------------------------------------------------------- Claves
  static const String claveModoTema = 'modo_tema';
  static const String clavePaletaFichas = 'paleta_fichas';
  static const String claveUltimoJugador = 'ultimo_jugador';
  static const String claveMejorPuntuacion = 'mejor_puntuacion';
  static const String claveVibracion = 'vibracion';

  /// Se llama una sola vez en `main()` antes de `runApp`.
  static Future<PreferenciasService> cargar() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferenciasService._(prefs);
  }

  // ------------------------------------------------------------ Tema
  Future<void> guardarModoTema(ThemeMode modo) =>
      _prefs.setString(claveModoTema, modo.name);

  /// Por defecto [ThemeMode.system] si no hay nada guardado.
  ThemeMode leerModoTema() {
    final valor = _prefs.getString(claveModoTema);
    return ThemeMode.values.firstWhere(
      (m) => m.name == valor,
      orElse: () => ThemeMode.system,
    );
  }

  // ------------------------------------------------- Color de fichas
  Future<void> guardarPaletaFichas(PaletaFichas paleta) =>
      _prefs.setString(clavePaletaFichas, paleta.name);

  PaletaFichas leerPaletaFichas() {
    final valor = _prefs.getString(clavePaletaFichas);
    return PaletaFichas.values.firstWhere(
      (p) => p.name == valor,
      orElse: () => PaletaFichas.clasica,
    );
  }

  // ------------------------------------------ Ampliaciones opcionales
  Future<void> guardarUltimoJugador(String nombre) =>
      _prefs.setString(claveUltimoJugador, nombre);

  String? leerUltimoJugador() => _prefs.getString(claveUltimoJugador);

  /// Guarda la mejor puntuación solo si supera la anterior.
  Future<void> actualizarMejorPuntuacion(int puntuacion) async {
    if (puntuacion > leerMejorPuntuacion()) {
      await _prefs.setInt(claveMejorPuntuacion, puntuacion);
    }
  }

  Future<void> guardarMejorPuntuacion(int puntuacion) =>
      _prefs.setInt(claveMejorPuntuacion, puntuacion);

  int leerMejorPuntuacion() => _prefs.getInt(claveMejorPuntuacion) ?? 0;

  Future<void> guardarVibracion(bool activa) =>
      _prefs.setBool(claveVibracion, activa);

  bool leerVibracion() => _prefs.getBool(claveVibracion) ?? true;
}
