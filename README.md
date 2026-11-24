# 2048 en Flutter — Acceso a datos + Interfaces

Práctica final: el juego **2048** en Flutter con persistencia local.

- **sqflite** (`game2048.db`): usuarios (login/registro con contraseña cifrada), historial de partidas, partida en curso, ranking y estadísticas. Migración de la versión 1 a la 2.
- **shared_preferences**: modo de tema (claro / oscuro / sistema), paleta de colores de las fichas, último jugador, mejor puntuación y vibración.
- **UI**: navegación con rutas centralizadas y `NavigationBar`, gestos (swipe, Dismissible + Deshacer, pulsación larga, RefreshIndicator, doble toque), widgets reutilizables y animaciones.

📄 Documentación completa: [`docs/DOCUMENTACION.md`](docs/DOCUMENTACION.md). Los diagramas están en Mermaid (GitHub los dibuja) y en Graphviz (`docs/img/*.dot`).

## Ejecutar

Hace falta Flutter (estable) y un emulador o dispositivo Android. sqflite no funciona en web.

```bash
flutter pub get
flutter run
```

La carpeta `android/` está generada con la plantilla de Flutter 3.50 (estable). Si tu versión de Flutter es más antigua y Gradle da errores, regenera la plataforma (no toca `lib/`):

```bash
flutter create . --platforms=android --org com.ericadmella
```

Tests de la lógica del juego, modelos, validadores y gestos:

```bash
flutter test
```

## Estructura

```
lib/
├── main.dart                 # carga preferencias antes de runApp
├── app.dart                  # MaterialApp (theme / darkTheme / themeMode)
├── app_scope.dart            # inyección de DAOs y ajustes (InheritedWidget)
├── routes.dart               # rutas con nombre centralizadas
├── models/                   # Usuario, Partida, PartidaGuardada, Estadisticas
├── data/                     # DatabaseHelper (singleton), DAOs, CambiosDatos
├── services/                 # PreferenciasService, AjustesController, sesión, hash
├── game/                     # lógica pura del 2048 + GameController
├── screens/                  # login, registro, shell, inicio, juego, historial, detalle, ranking, ajustes
├── widgets/                  # TileWidget, BoardWidget, ScoreCard, StatCard, PartidaListItem,
│                             # ConfirmDialog, EmptyStateView, AsyncDataView
├── theme/app_theme.dart      # colores de fichas, tamaños, espaciados, estilos
└── utils/                    # formato y validadores
```

## Regenerar los diagramas en PNG

```bash
cd docs/img
for f in er navegacion arquitectura; do dot -Tpng -Gdpi=160 $f.dot -o $f.png; done
```
