module.exports = {
  httpPort: process.env.HTTP_PORT || 3000,
  wsPort: process.env.WS_PORT || 3001,
  maxPlayersPerRoom: 8,
  tickRate: 30,
  arena: {
    width: 960,
    height: 540,
    // Debe coincidir con la plataforma visual del cliente.
    platform: { x: 210, y: 392, width: 540, height: 42 },
  },
  player: {
    width: 44,
    height: 58,
    speed: 285,
    jumpForce: 690,
    gravity: 1700,
    maxHp: 100,
    punchDamage: 12,
    punchRange: 72,
    punchCooldownMs: 480,
    knockbackX: 430,
    knockbackY: 260,
    spawnSpacing: 62,
  },
};
