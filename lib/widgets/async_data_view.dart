import 'package:flutter/material.dart';

import '../data/data_exception.dart';
import 'empty_state_view.dart';

/// Gestiona los estados de un [Future]: carga (indicador), error (mensaje y
/// botón «Reintentar») y datos (llama a [builder]). Opcionalmente muestra un
/// [EmptyStateView] si [esVacio] devuelve true.
///
/// Se usa en todas las pantallas que leen de la base de datos.
class AsyncDataView<T> extends StatelessWidget {
  const AsyncDataView({
    super.key,
    required this.future,
    required this.builder,
    required this.onReintentar,
    this.esVacio,
    this.vacio,
    this.desplazable = false,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T datos) builder;
  final VoidCallback onReintentar;
  final bool Function(T datos)? esVacio;
  final Widget? vacio;

  /// Si es true, los estados de carga/error/vacío se envuelven en un
  /// scroll para que funcione el RefreshIndicator que los contenga.
  final bool desplazable;

  Widget _envolver(Widget hijo) {
    if (!desplazable) return hijo;
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: constraints.maxHeight, child: hijo),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _envolver(const Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          final mensaje = error is DataException
              ? error.mensaje
              : 'Ha ocurrido un error inesperado';
          return _envolver(EmptyStateView(
            icono: Icons.error_outline,
            mensaje: mensaje,
            accion: OutlinedButton.icon(
              onPressed: onReintentar,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ));
        }
        final datos = snapshot.data as T;
        if (esVacio != null && esVacio!(datos)) {
          return _envolver(
              vacio ?? const EmptyStateView(mensaje: 'No hay datos'));
        }
        return builder(context, datos);
      },
    );
  }
}
