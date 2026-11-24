import 'package:flutter/material.dart';

/// Diálogo genérico de confirmación con título, mensaje y textos de botones.
///
/// Se usa para borrar una partida, borrar el historial, reiniciar la partida
/// y salir de la partida. Devuelve `true` si el usuario confirma.
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.titulo,
    required this.mensaje,
    this.textoConfirmar = 'Aceptar',
    this.textoCancelar = 'Cancelar',
    this.destructivo = false,
  });

  final String titulo;
  final String mensaje;
  final String textoConfirmar;
  final String textoCancelar;

  /// Si es true el botón de confirmar se pinta con el color de error.
  final bool destructivo;

  /// Muestra el diálogo y devuelve `true` solo si se pulsa confirmar.
  static Future<bool> mostrar(
    BuildContext context, {
    required String titulo,
    required String mensaje,
    String textoConfirmar = 'Aceptar',
    String textoCancelar = 'Cancelar',
    bool destructivo = false,
  }) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(
        titulo: titulo,
        mensaje: mensaje,
        textoConfirmar: textoConfirmar,
        textoCancelar: textoCancelar,
        destructivo: destructivo,
      ),
    );
    return r ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(titulo),
      content: Text(mensaje),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(textoCancelar),
        ),
        FilledButton(
          style: destructivo
              ? FilledButton.styleFrom(
                  backgroundColor: esquema.error,
                  foregroundColor: esquema.onError,
                  minimumSize: Size.zero,
                )
              : FilledButton.styleFrom(minimumSize: Size.zero),
          onPressed: () => Navigator.pop(context, true),
          child: Text(textoConfirmar),
        ),
      ],
    );
  }
}
