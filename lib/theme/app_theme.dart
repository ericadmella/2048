import 'package:flutter/material.dart';

/// Constantes visuales y temas de la aplicación.
///
/// Ningún color, tamaño o espaciado debe escribirse "a mano" en las
/// pantallas o widgets: se leen de aquí o del tema activo
/// (`Theme.of(context)`).

// ------------------------------------------------------------------ Espacios
class AppSpacing {
  AppSpacing._();
  static const double xs = 4;
  static const double s = 8;
  static const double m = 12;
  static const double l = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

// ------------------------------------------------------------------- Tamaños
class AppSizes {
  AppSizes._();
  static const int tamanoTablero = 4;
  static const double radioFicha = 8;
  static const double radioTablero = 12;
  static const double radioTarjeta = 16;
  static const double separacionFichas = 8;
  static const double anchoMaximoTablero = 480;
  static const double anchoMaximoFormulario = 420;
  static const double iconoEstado = 72;
  static const double iconoStat = 28;
  static const double fichaMiniatura = 56;
  static const double umbralSwipe = 24; // px mínimos para aceptar un swipe
  static const double umbralVelocidadSwipe = 250; // px/s
  static const Duration animacionFicha = Duration(milliseconds: 140);
  static const Duration animacionFusion = Duration(milliseconds: 120);
}

// ------------------------------------------------------- Estilos de texto
class AppTextStyles {
  AppTextStyles._();

  static const TextStyle tituloJuego = TextStyle(
    fontSize: 56,
    fontWeight: FontWeight.w900,
    letterSpacing: -1,
  );

  static const TextStyle etiquetaMarcador = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
  );

  static const TextStyle valorMarcador = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle valorStat = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
  );

  /// Tamaño de fuente de una ficha en función de su valor y del lado de la
  /// ficha, para que números de 4 cifras quepan.
  static TextStyle ficha(int valor, double lado) {
    final digitos = valor.toString().length;
    final factor = switch (digitos) {
      1 || 2 => 0.45,
      3 => 0.36,
      4 => 0.28,
      _ => 0.22,
    };
    return TextStyle(fontSize: lado * factor, fontWeight: FontWeight.w800);
  }
}

// ------------------------------------------------------ Paletas de fichas
/// Paletas seleccionables en Ajustes (se guardan en shared_preferences).
enum PaletaFichas {
  clasica('Clásica', Color(0xFFEDC22E)),
  oceano('Océano', Color(0xFF1E88E5)),
  bosque('Bosque', Color(0xFF43A047)),
  atardecer('Atardecer', Color(0xFF8E24AA));

  const PaletaFichas(this.etiqueta, this.semilla);
  final String etiqueta;
  final Color semilla;
}

/// Colores del tablero y de las fichas, como extensión del tema. Así los
/// widgets los leen con `Theme.of(context).extension<TileColors>()` y
/// cambian al instante con el modo claro/oscuro o la paleta.
@immutable
class TileColors extends ThemeExtension<TileColors> {
  const TileColors({
    required this.fondos,
    required this.vacia,
    required this.tablero,
  });

  /// fondos[0] = ficha 2, fondos[1] = 4 ... fondos[10] = 2048, fondos[11] = >2048.
  final List<Color> fondos;
  final Color vacia;
  final Color tablero;

  Color fondo(int valor) {
    if (valor <= 0) return vacia;
    var indice = 0;
    var v = valor;
    while (v > 2) {
      v >>= 1;
      indice++;
    }
    return fondos[indice.clamp(0, fondos.length - 1)];
  }

  /// Texto blanco u oscuro según el contraste con el fondo: legible en
  /// ambos modos sea cual sea la paleta.
  Color texto(int valor) {
    final f = fondo(valor);
    return ThemeData.estimateBrightnessForColor(f) == Brightness.dark
        ? Colors.white
        : const Color(0xFF3C3A32);
  }

  @override
  TileColors copyWith({List<Color>? fondos, Color? vacia, Color? tablero}) =>
      TileColors(
        fondos: fondos ?? this.fondos,
        vacia: vacia ?? this.vacia,
        tablero: tablero ?? this.tablero,
      );

  @override
  TileColors lerp(TileColors? other, double t) {
    if (other == null) return this;
    return TileColors(
      fondos: List<Color>.generate(
        fondos.length,
        (i) => Color.lerp(fondos[i], other.fondos[i], t)!,
      ),
      vacia: Color.lerp(vacia, other.vacia, t)!,
      tablero: Color.lerp(tablero, other.tablero, t)!,
    );
  }

  static const int _numFondos = 12;

  /// Construye la paleta para un brillo concreto.
  factory TileColors.de(PaletaFichas paleta, Brightness brillo) {
    final oscuro = brillo == Brightness.dark;
    if (paleta == PaletaFichas.clasica) {
      return oscuro ? _clasicaOscura : _clasicaClara;
    }
    final (inicio, fin) = switch ((paleta, oscuro)) {
      (PaletaFichas.oceano, false) => (
          const Color(0xFFE3F2FD),
          const Color(0xFF0D47A1)
        ),
      (PaletaFichas.oceano, true) => (
          const Color(0xFF263D57),
          const Color(0xFF90CAF9)
        ),
      (PaletaFichas.bosque, false) => (
          const Color(0xFFE8F5E9),
          const Color(0xFF1B5E20)
        ),
      (PaletaFichas.bosque, true) => (
          const Color(0xFF26402A),
          const Color(0xFFA5D6A7)
        ),
      (PaletaFichas.atardecer, false) => (
          const Color(0xFFF3E5F5),
          const Color(0xFF880E4F)
        ),
      (_, _) => (const Color(0xFF3F2A47), const Color(0xFFF48FB1)),
    };
    return TileColors(
      fondos: List<Color>.generate(
        _numFondos,
        (i) => Color.lerp(inicio, fin, i / (_numFondos - 1))!,
      ),
      vacia: oscuro ? const Color(0xFF2E2E33) : const Color(0xFFE0E0E0),
      tablero: oscuro ? const Color(0xFF1F1F23) : const Color(0xFFBDBDBD),
    );
  }

  static const TileColors _clasicaClara = TileColors(
    fondos: [
      Color(0xFFEEE4DA),
      Color(0xFFEDE0C8),
      Color(0xFFF2B179),
      Color(0xFFF59563),
      Color(0xFFF67C5F),
      Color(0xFFF65E3B),
      Color(0xFFEDCF72),
      Color(0xFFEDCC61),
      Color(0xFFEDC850),
      Color(0xFFEDC53F),
      Color(0xFFEDC22E),
      Color(0xFF3C3A32),
    ],
    vacia: Color(0xFFCDC1B4),
    tablero: Color(0xFFBBADA0),
  );

  static const TileColors _clasicaOscura = TileColors(
    fondos: [
      Color(0xFF5A524A),
      Color(0xFF6B5D4B),
      Color(0xFFB5703A),
      Color(0xFFC0602F),
      Color(0xFFC24E35),
      Color(0xFFC23B1E),
      Color(0xFFB89A3A),
      Color(0xFFB8952E),
      Color(0xFFB89020),
      Color(0xFFB88A12),
      Color(0xFFD4A30E),
      Color(0xFFF5F0E6),
    ],
    vacia: Color(0xFF3A3633),
    tablero: Color(0xFF2A2725),
  );
}

// -------------------------------------------------------------------- Temas
class AppTheme {
  AppTheme._();

  static ThemeData claro(PaletaFichas paleta) =>
      _crear(paleta, Brightness.light);
  static ThemeData oscuro(PaletaFichas paleta) =>
      _crear(paleta, Brightness.dark);

  static ThemeData _crear(PaletaFichas paleta, Brightness brillo) {
    final esquema = ColorScheme.fromSeed(
      seedColor: paleta.semilla,
      brightness: brillo,
    );
    final forma = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radioTarjeta),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      brightness: brillo,
      extensions: [TileColors.de(paleta, brillo)],
      appBarTheme: const AppBarTheme(centerTitle: true),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: forma,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: forma,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme:
          const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  /// Decoración común para los campos de texto de los formularios.
  static InputDecoration campo(String etiqueta, IconData icono) =>
      InputDecoration(
        labelText: etiqueta,
        prefixIcon: Icon(icono),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.radioTarjeta),
        ),
      );
}

/// Atajo para leer los colores del tablero del tema activo.
extension TileColorsContext on BuildContext {
  TileColors get tileColors => Theme.of(this).extension<TileColors>()!;
}
