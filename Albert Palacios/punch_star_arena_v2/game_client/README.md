# Punch Star Arena - Cliente

Cliente Flutter + Flame para un battle royale 2D lateral.

## Ejecutar

```bash
flutter pub get
flutter run -d chrome
```

Antes inicia el servidor:

```bash
cd ../game_server
npm install
npm start
```

## Controles

- A / Flecha izquierda: moverse a la izquierda
- D / Flecha derecha: moverse a la derecha
- Espacio / W / Flecha arriba: saltar
- J / Enter: puñetazo

## Configuración

La URL del servidor está en `lib/config.dart`.

Para Proxmox o red local cambia:

```dart
const String defaultServerUrl = 'ws://TU_IP:3001';
```
