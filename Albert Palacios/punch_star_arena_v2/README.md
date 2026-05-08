# Punch Star Arena v2

Battle royale 2D espacial tipo Smash Bros simple.

## Qué incluye esta versión

- Cliente Flutter + Flame.
- Servidor Node.js + WebSockets.
- Salas/lobby de 2 a 8 jugadores, siguiendo la idea técnica del proyecto de referencia.
- Plataforma central espacial.
- Movimiento lateral, salto, gravedad y caída al vacío.
- Combate cuerpo a cuerpo con vida clásica de 100 HP.
- Knockback al recibir golpes.
- Spawn separado: cuando entra otro jugador no aparece encima de los demás.
- HUD con vida, cantidad de jugadores y controles.
- Assets pixel art libres/generados para este proyecto.
- Código comentado para entender cada parte.

## Ejecutar servidor

```bash
cd game_server
npm install
npm start
```

Servidor HTTP: `http://localhost:3000`  
Servidor WebSocket: `ws://localhost:3001`

## Ejecutar cliente

```bash
cd game_client
flutter pub get
flutter run -d windows
```

También puedes usar Chrome:

```bash
flutter run -d chrome
```

## Controles

- `A / D` o flechas: mover.
- `W / Espacio / Flecha arriba`: saltar.
- `J / Enter`: puñetazo.

## Proxmox / LAN

Cambia la IP en:

```txt
game_client/lib/config.dart
```

Por ejemplo:

```dart
const String defaultServerUrl = 'ws://192.168.1.34:3001';
```

Asegúrate de permitir `node.exe` en el firewall.

## Nota técnica

El cliente solo manda inputs. El servidor calcula física, vida, golpes y posiciones. Esto evita que cada cliente invente su propia partida y facilita jugar desde varios PCs o máquinas en red.
