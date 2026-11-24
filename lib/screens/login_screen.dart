import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/data_exception.dart';
import '../routes.dart';
import '../services/sesion_service.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  bool _cargando = false;
  bool _ocultar = true;
  bool _inicializado = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_inicializado) {
      // Rellenamos el último jugador guardado en shared_preferences.
      _usuarioCtrl.text =
          AppScope.of(context).preferencias.leerUltimoJugador() ?? '';
      _inicializado = true;
    }
  }

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    if (!_formKey.currentState!.validate()) return;
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _cargando = true);
    try {
      final usuario = await scope.usuarioDao.autenticar(
        _usuarioCtrl.text,
        _contrasenaCtrl.text,
      );
      if (usuario == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Usuario o contraseña incorrectos')),
        );
        return;
      }
      SesionService.instance.iniciar(usuario);
      await scope.preferencias.guardarUltimoJugador(usuario.usuario);
      navigator.pushReplacementNamed(AppRoutes.inicio);
    } on DataException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                  maxWidth: AppSizes.anchoMaximoFormulario),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '2048',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.tituloJuego
                          .copyWith(color: tema.colorScheme.primary),
                    ),
                    Text(
                      'Inicia sesión para jugar',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    TextFormField(
                      controller: _usuarioCtrl,
                      decoration:
                          AppTheme.campo('Usuario', Icons.person_outline),
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Introduce tu usuario'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.l),
                    TextFormField(
                      controller: _contrasenaCtrl,
                      obscureText: _ocultar,
                      decoration:
                          AppTheme.campo('Contraseña', Icons.lock_outline)
                              .copyWith(
                        suffixIcon: IconButton(
                          tooltip: _ocultar ? 'Mostrar' : 'Ocultar',
                          icon: Icon(_ocultar
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () => setState(() => _ocultar = !_ocultar),
                        ),
                      ),
                      onFieldSubmitted: (_) => _entrar(),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Introduce tu contraseña'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: _cargando ? null : _entrar,
                      child: _cargando
                          ? const SizedBox.square(
                              dimension: AppSpacing.xl,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Entrar'),
                    ),
                    const SizedBox(height: AppSpacing.m),
                    OutlinedButton(
                      onPressed: _cargando
                          ? null
                          : () =>
                              Navigator.pushNamed(context, AppRoutes.registro),
                      child: const Text('Crear una cuenta'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
