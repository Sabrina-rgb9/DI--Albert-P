const express = require('express');
const WebSocket = require('ws');

const config = require('./config');
const { rooms, joinRoom, leaveRoom, broadcast } = require('./rooms');
const { updateRoom } = require('./gameLogic');

const app = express();

app.get('/', (_, res) => {
  res.json({
    name: 'Punch Star Arena Server',
    websocket: `ws://localhost:${config.wsPort}`,
    status: 'ok',
  });
});

app.listen(config.httpPort, () => {
  console.log(`HTTP server on http://localhost:${config.httpPort}`);
});

const wss = new WebSocket.Server({ port: config.wsPort });

wss.on('connection', (ws) => {
  console.log('Client connected');

  ws.on('message', (raw) => {
    let message;
    try {
      message = JSON.parse(raw.toString());
    } catch {
      return;
    }

    if (message.type === 'join') {
      joinRoom(ws, message.roomCode, message.name);
      return;
    }

    if (message.type === 'input') {
      const room = rooms.get(ws.roomCode);
      if (!room) return;

      const player = room.players.get(ws.playerId);
      if (!player) return;

      // El cliente manda intención, no posición. El servidor manda autoridad.
      player.input = {
        left: Boolean(message.left),
        right: Boolean(message.right),
        jump: Boolean(message.jump),
        attack: Boolean(message.attack),
      };
    }
  });

  ws.on('close', () => {
    leaveRoom(ws);
    console.log('Client disconnected');
  });
});

// Game loop autoritativo.
// Calcula física, ataques y vida en servidor, luego sincroniza a todos.
const dt = 1 / config.tickRate;
setInterval(() => {
  for (const room of rooms.values()) {
    updateRoom(room, dt);
    broadcast(room, room.lastState);
  }
}, 1000 / config.tickRate);

console.log(`WebSocket server on ws://localhost:${config.wsPort}`);
