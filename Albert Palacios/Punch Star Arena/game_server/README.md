# Punch Star Arena - Servidor

Servidor Node.js para partidas online por WebSockets.

## Ejecutar

```bash
npm install
npm start
```

Servidor:
- HTTP: http://localhost:3000
- WebSocket: ws://localhost:3001

## Proxmox / red local

Abre el puerto 3001 y en el cliente cambia:

```dart
const String defaultServerUrl = 'ws://IP_DEL_SERVIDOR:3001';
```
