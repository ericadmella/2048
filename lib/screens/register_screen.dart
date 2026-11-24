import 'package:flutter/material.dart';

import '../app_scope.dart';
import '../data/data_exception.dart';
import '../routes.dart';
import '../services/sesion_service.dart';
import '../theme/app_theme.dart';
import '../utils/validadores.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usuarioCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _contrasenaCtrl = TextEditingController();
  final _repetirCtrl = TextEditingController();
  bool _cargando = false;

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _emailCtrl.dispose();
    _contrasenaCtrl.dispose();
    _repetirCtrl.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    final scope = AppScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _cargando = true);
    try {
      final usuario = await scope.usuarioDao.registrar(
        usuario: _usuarioCtrl.text,
        email: _emailCtrl.text,
        contrasena: _contrasenaCtrl.text,
      );
      SesionService.instance.iniciar(usuario);
      await scope.preferencias.guardarUltimoJugador(usuario.usuario);
      messenger.showSnackBar(
        SnackBar(content: Text('¡Bienvenido, ${usuario.usuario}!')),
      );
      navigator.pushNamedAndRemoveUntil(AppRoutes.inicio, (_) => false);
    } on DataException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.mensaje)));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear cuenta')),
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
                    TextFormField(
                      controller: _usuarioCtrl,
                      decoration:
                          AppTheme.campo('Usuario', Icons.person_outline),
                      textInputAction: TextInputAction.next,
                      validator: Validadores.usuario,
                    ),
                    const SizedBox(height: AppSpacing.l),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: AppTheme.campo('Email', Icons.email_outlined),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: Validadores.email,
                    ),
                    const SizedBox(height: AppSpacing.l),
                    TextFormField(
                      controller: _contrasenaCtrl,
                      decoration:
                          AppTheme.campo('Contraseña', Icons.lock_outline),
                      obscureText: true,
                      textInputAction: TextInputAction.next,
                      validator: Validadores.contrasena,
                    ),
                    const SizedBox(height: AppSpacing.l),
                    TextFormField(
                      controller: _repetirCtrl,
                      decoration: AppTheme.campo(
                          'Repite la contraseña', Icons.lock_reset),
                      obscureText: true,
                      onFieldSubmitted: (_) => _registrar(),
                      validator: (v) => v != _contrasenaCtrl.text
                          ? 'Las contraseñas no coinciden'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: _cargando ? null : _registrar,
                      child: _cargando
                          ? const SizedBox.square(
                              dimension: AppSpacing.xl,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Registrarme'),
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
