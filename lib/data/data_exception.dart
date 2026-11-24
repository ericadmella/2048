/// Error de la capa de datos con un mensaje apto para mostrar al usuario.
class DataException implements Exception {
  final String mensaje;
  final Object? causa;

  const DataException(this.mensaje, [this.causa]);

  @override
  String toString() =>
      'DataException: $mensaje${causa != null ? ' ($causa)' : ''}';
}
