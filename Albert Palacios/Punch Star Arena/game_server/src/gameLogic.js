const config = require('./config');

const colors = ['red', 'blue', 'green', 'yellow', 'purple', 'cyan', 'orange', 'white'];

function createPlayer(id, name, index) {
  const spawnX = 220 + (index % 8) * 75;
  return {
    id,
    name: name || 'Astronauta',
    color: colors[index % colors.length],
    x: spawnX,
    y: config.arena.platform.y - 40,
    vx: 0,
    vy: 0,
    hp: config.player.maxHp,
    facing: 1,
    isAlive: true,
    isAttacking: false,
    input: { left: false, right: false, jump: false, attack: false },
    lastPunchAt: 0,
    attackTimer: 0,
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

  p.vx = ax * playerCfg.speed;
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

  // Límites laterales suaves.
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
    Math.abs(feetY - platform.y) < 3 &&
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
  player.vx += direction * config.player.knockbackX;
  player.vy = -config.player.knockbackY;

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
