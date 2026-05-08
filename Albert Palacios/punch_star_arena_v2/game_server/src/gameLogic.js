const config = require('./config');

const colors = ['red', 'blue', 'green', 'yellow', 'purple', 'cyan', 'orange', 'white'];

/**
 * Calcula un punto de aparición que no se superponga con otro jugador.
 * La referencia ya usaba sala/lobby; aquí añadimos separación clara para que
 * al conectarse varios clientes no nazcan encima unos de otros.
 */
function calculateSpawnX(room, index) {
  const platform = config.arena.platform;
  const spacing = config.player.spawnSpacing;
  const center = platform.x + platform.width / 2;

  const offsets = [0, -1, 1, -2, 2, -3, 3, -4];
  const occupied = Array.from(room.players.values()).map((p) => p.x);

  for (const off of offsets) {
    const candidate = center + off * spacing;
    const inside = candidate > platform.x + 40 && candidate < platform.x + platform.width - 40;
    const free = occupied.every((x) => Math.abs(x - candidate) >= spacing * 0.75);
    if (inside && free) return candidate;
  }

  // Fallback por si la sala está llena y todos los puntos principales ocupados.
  return platform.x + 45 + (index % config.maxPlayersPerRoom) * spacing;
}

function createPlayer(id, name, index, room) {
  const spawnX = calculateSpawnX(room, index);
  return {
    id,
    name: name || `Jugador ${index + 1}`,
    color: colors[index % colors.length],
    x: spawnX,
    y: config.arena.platform.y - config.player.height / 2,
    vx: 0,
    vy: 0,
    hp: config.player.maxHp,
    facing: spawnX < config.arena.platform.x + config.arena.platform.width / 2 ? 1 : -1,
    isAlive: true,
    isAttacking: false,
    input: { left: false, right: false, jump: false, attack: false },
    lastPunchAt: 0,
    attackTimer: 0,
    hurtTimer: 0,
  };
}

function updateRoom(room, dt) {
  const players = Array.from(room.players.values());

  for (const p of players) {
    updatePlayerPhysics(p, dt);
    handleAttack(room, p);
  }

  room.lastState = serializeRoom(room);
}

function updatePlayerPhysics(p, dt) {
  if (!p.isAlive) return;

  const playerCfg = config.player;
  const platform = config.arena.platform;

  let ax = 0;
  if (p.input.left) ax -= 1;
  if (p.input.right) ax += 1;

  // Si el jugador acaba de recibir un golpe, dejamos que el knockback se note
  // unos instantes antes de sustituirlo por el movimiento del input.
  if (p.hurtTimer > 0) {
    p.hurtTimer -= dt;
    p.vx *= 0.92;
  } else {
    p.vx = ax * playerCfg.speed;
  }

  if (ax !== 0) p.facing = ax > 0 ? 1 : -1;

  const onPlatform = isOnPlatform(p);
  if (p.input.jump && onPlatform) {
    p.vy = -playerCfg.jumpForce;
  }

  p.vy += playerCfg.gravity * dt;

  p.x += p.vx * dt;
  p.y += p.vy * dt;

  // Colisión simple con plataforma central.
  const halfW = playerCfg.width / 2;
  const feetY = p.y + playerCfg.height / 2;

  const withinPlatformX =
    p.x + halfW > platform.x && p.x - halfW < platform.x + platform.width;

  if (p.vy >= 0 && withinPlatformX && feetY >= platform.y && feetY <= platform.y + 34) {
    p.y = platform.y - playerCfg.height / 2;
    p.vy = 0;
  }

  // Límites laterales suaves de la arena.
  p.x = Math.max(20, Math.min(config.arena.width - 20, p.x));

  // Caer al vacío elimina al jugador.
  if (p.y > config.arena.height + 120) {
    damagePlayer(p, 999, p.facing, true);
  }

  if (p.attackTimer > 0) {
    p.attackTimer -= dt;
  } else {
    p.isAttacking = false;
  }
}

function isOnPlatform(p) {
  const platform = config.arena.platform;
  const feetY = p.y + config.player.height / 2;
  return (
    Math.abs(feetY - platform.y) < 4 &&
    p.x > platform.x &&
    p.x < platform.x + platform.width
  );
}

function handleAttack(room, attacker) {
  if (!attacker.isAlive || !attacker.input.attack) return;

  const now = Date.now();
  if (now - attacker.lastPunchAt < config.player.punchCooldownMs) return;

  attacker.lastPunchAt = now;
  attacker.isAttacking = true;
  attacker.attackTimer = 0.16;

  for (const target of room.players.values()) {
    if (target.id === attacker.id || !target.isAlive) continue;

    const dx = target.x - attacker.x;
    const dy = Math.abs(target.y - attacker.y);
    const inFront = attacker.facing > 0 ? dx > 0 : dx < 0;
    const closeEnough = Math.abs(dx) <= config.player.punchRange && dy <= 58;

    if (inFront && closeEnough) {
      damagePlayer(target, config.player.punchDamage, attacker.facing, false);
    }
  }
}

function damagePlayer(player, amount, direction, instantDeath) {
  player.hp -= amount;
  player.vx = direction * config.player.knockbackX;
  player.vy = -config.player.knockbackY;
  player.hurtTimer = 0.22;

  if (instantDeath || player.hp <= 0) {
    player.hp = 0;
    player.isAlive = false;
  }
}

function serializeRoom(room) {
  return {
    type: 'state',
    roomCode: room.code,
    players: Array.from(room.players.values()).map((p) => ({
      id: p.id,
      name: p.name,
      color: p.color,
      x: Math.round(p.x),
      y: Math.round(p.y),
      vx: Math.round(p.vx),
      vy: Math.round(p.vy),
      hp: p.hp,
      facing: p.facing,
      isAttacking: p.isAttacking,
      isAlive: p.isAlive,
    })),
  };
}

module.exports = {
  createPlayer,
  updateRoom,
  serializeRoom,
};
