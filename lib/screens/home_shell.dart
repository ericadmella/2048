import 'package:flutter/material.dart';

import 'ajustes_screen.dart';
import 'historial_screen.dart';
import 'inicio_screen.dart';
import 'ranking_screen.dart';

/// Contenedor de la navegación principal con [NavigationBar] (Material 3).
///
/// Se usa IndexedStack para conservar el estado de cada pestaña (filtros,
/// posición del scroll) al cambiar entre ellas.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _indice = 0;

  void _irA(int indice) => setState(() => _indice = indice);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _indice,
        children: [
          InicioScreen(onIrAPestana: _irA),
          const HistorialScreen(),
          const RankingScreen(),
          const AjustesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _irA,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Ranking',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

/// Índices de las pestañas, para no usar números mágicos.
class Pestanas {
  Pestanas._();
  static const int inicio = 0;
  static const int historial = 1;
  static const int ranking = 2;
  static const int ajustes = 3;
}
