import 'package:flutter/foundation.dart';

import '../models/usuario.dart';

/// Usuario con la sesión iniciada (en memoria).
class SesionService extends ChangeNotifier {
  SesionService._();
  static final SesionService instance = SesionService._();

  Usuario? _usuario;

  Usuario? get usuario => _usuario;
  bool get haySesion => _usuario != null;
  String get nombre => _usuario?.usuario ?? 'Invitado';

  void iniciar(Usuario usuario) {
    _usuario = usuario;
    notifyListeners();
  }

  void cerrar() {
    _usuario = null;
    notifyListeners();
  }
}
