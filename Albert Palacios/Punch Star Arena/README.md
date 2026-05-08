# Punch Star Arena

Battle royale espacial 2D lateral estilo Smash Bros simple.

## Qué incluye

- Cliente Flutter + Flame
- Servidor Node.js + WebSocket
- Lobby por código de sala
- 2 a 8 jugadores
- Movimiento lateral
- Salto y gravedad
- Plataforma central espacial
- Ataque cuerpo a cuerpo
- Vida clásica 100 HP
- Knockback
- Eliminación por vida o caída
- Assets pixel art generados para este proyecto

## Ejecutar servidor

```bash
cd game_server
npm install
npm start
```

## Ejecutar cliente

```bash
cd game_client
flutter pub get
flutter run -d chrome
```

## Controles

- A / Flecha izquierda: izquierda
- D / Flecha derecha: derecha
- W / Espacio / Flecha arriba: salto
- J / Enter: puñetazo

## Proxmox / red local

1. Ejecuta el servidor en la VM o máquina elegida.
2. Asegúrate de abrir el puerto `3001`.
3. En `game_client/lib/config.dart`, cambia:

```dart
const String defaultServerUrl = 'ws://localhost:3001';
```

por:

```dart
const String defaultServerUrl = 'ws://IP_DE_TU_SERVIDOR:3001';
```

## Notas

Esta es una primera base jugable y comentada. Está pensada para ampliarse con:
- pantalla de ganador
- respawn opcional
- sonidos
- power ups
- animaciones más finas
- selección de personaje
- tilesets más grandes
