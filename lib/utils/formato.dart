/// Funciones de formato compartidas por pantallas y widgets.
class Formato {
  Formato._();

  /// 75 -> "01:15", 3725 -> "1:02:05".
  static String duracion(int segundos) {
    final h = segundos ~/ 3600;
    final m = (segundos % 3600) ~/ 60;
    final s = segundos % 60;
    String dos(int n) => n.toString().padLeft(2, '0');
    return h > 0 ? '$h:${dos(m)}:${dos(s)}' : '${dos(m)}:${dos(s)}';
  }

  /// "22/11/2026 18:05"
  static String fecha(DateTime f) {
    String dos(int n) => n.toString().padLeft(2, '0');
    return '${dos(f.day)}/${dos(f.month)}/${f.year} ${dos(f.hour)}:${dos(f.minute)}';
  }

  static String decimal(double valor) => valor.toStringAsFixed(1);
}
