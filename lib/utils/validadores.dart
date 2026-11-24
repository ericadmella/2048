/// Validadores de formularios (registro / login).
class Validadores {
  Validadores._();

  static final RegExp _regexEmail =
      RegExp(r'^[\w.+\-]+@[A-Za-z0-9\-]+(\.[A-Za-z0-9\-]+)*\.[A-Za-z]{2,}$');

  static String? usuario(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Introduce un nombre de usuario';
    if (t.length < 3) return 'Mínimo 3 caracteres';
    if (t.length > 20) return 'Máximo 20 caracteres';
    return null;
  }

  /// Email con formato correcto: debe contener '@' y un dominio válido.
  static String? email(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Introduce tu email';
    if (!t.contains('@')) return 'El email debe contener @';
    if (!_regexEmail.hasMatch(t)) return 'Formato de email no válido';
    return null;
  }

  static String? contrasena(String? v) {
    final t = v ?? '';
    if (t.length < 6) return 'Mínimo 6 caracteres';
    return null;
  }
}
