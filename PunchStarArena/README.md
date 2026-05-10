# Punch Star Arena - versión basada en WrathInJapan

Adaptación real sobre la estructura del proyecto de referencia `WrathInJapan`.

## Qué conserva del proyecto de referencia

- `game_client` Flutter con la misma arquitectura.
- `game_server` Node.js con WebSockets.
- `game_server/proxmox` completo.
- `assets/levels/game_data.json`.
- `assets/levels/animations/animations.json`.
- `assets/levels/tilemaps/level_000_layer_000.json`.
- `assets/levels/tilemaps/level_000_layer_001.json`.
- `assets/levels/paths/level_000_paths.json`.
- `assets/levels/zones/level_000_zones.json`.
- Scripts `buildFlutterWeb.sh` y `getAssets.sh`.

## Qué se ha cambiado

- Ambientación espacial.
- Nombre: `Punch Star Arena`.
- Fondo espacial.
- Plataforma/tileset futurista.
- Sprites de astronauta pixel art generados para este proyecto.
- Spawns separados para hasta 8 jugadores.
- `MAX_PLAYERS = 8`.
- Servidor arrancable con `npm start`, `npm run dev` o `node app.js`.

## Ejecutar servidor

```bash
cd game_server
npm install
npm start
```

También funciona:

```bash
node app.js
```

## Ejecutar cliente

```bash
cd game_client
flutter pub get
flutter run -d chrome
```

Para Windows desktop, usa una ruta corta, por ejemplo `C:\PunchStar`, para evitar el límite de 260 caracteres de CMake/MSBuild:

```bash
flutter run -d windows
```

## Proxmox

La carpeta `game_server/proxmox` se conserva. Antes de usar los scripts revisa `config.env` o las variables que pida cada script, igual que en el proyecto de referencia.
