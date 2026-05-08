const { v4: uuidv4 } = require('uuid');
const config = require('./config');
const { createPlayer } = require('./gameLogic');

const rooms = new Map();

function getOrCreateRoom(code) {
  const roomCode = (code || 'STAR').toUpperCase().slice(0, 12);
  if (!rooms.has(roomCode)) {
    rooms.set(roomCode, {
      code: roomCode,
      players: new Map(),
      sockets: new Map(),
      lastState: null,
    });
  }
  return rooms.get(roomCode);
}

function joinRoom(ws, roomCode, playerName) {
  const room = getOrCreateRoom(roomCode);

  if (room.players.size >= config.maxPlayersPerRoom) {
    ws.send(JSON.stringify({ type: 'error', message: 'Sala llena. Máximo 8 jugadores.' }));
    return null;
  }

  const id = uuidv4();
  const player = createPlayer(id, playerName, room.players.size, room);
  room.players.set(id, player);
  room.sockets.set(id, ws);

  ws.playerId = id;
  ws.roomCode = room.code;

  ws.send(JSON.stringify({ type: 'welcome', id, roomCode: room.code }));
  return player;
}

function leaveRoom(ws) {
  if (!ws.roomCode || !ws.playerId) return;

  const room = rooms.get(ws.roomCode);
  if (!room) return;

  room.players.delete(ws.playerId);
  room.sockets.delete(ws.playerId);

  if (room.players.size === 0) {
    rooms.delete(room.code);
  }
}

function broadcast(room, payload) {
  const data = JSON.stringify(payload);
  for (const socket of room.sockets.values()) {
    if (socket.readyState === 1) {
      socket.send(data);
    }
  }
}

module.exports = {
  rooms,
  joinRoom,
  leaveRoom,
  broadcast,
};
