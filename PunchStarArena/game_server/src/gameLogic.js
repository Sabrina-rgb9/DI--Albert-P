'use strict';

const { loadMultiplayerLevel } = require('./multiplayerLevelData.js');

// Game rules and settings.
// These constants define how the server simulates gameplay.

// Match state rules.
const MAX_PLAYERS = 8;
const COUNTDOWN_DURATION_MS = 10 * 1000;
const RESULTS_DURATION_MS = 10 * 1000;
const TARGET_FPS_FALLBACK = 60;

// Player hitbox and movement bounds.
const PLAYER_WIDTH = 20;
const PLAYER_HEIGHT = 20;
const PLAYER_START_X = 460;
const PLAYER_START_Y = 615;
const PLAYER_START_STEP_X = 50;
const PLAYER_START_STEP_Y = 0;

// Horizontal movement tuning.
const MOVE_SPEED_PER_SECOND = 260;
const NORMAL_ACCELERATION_PER_SECOND = 1400;
const NORMAL_DECELERATION_PER_SECOND = 1600;
const HORIZONTAL_AIR_FACTOR = 0.75;
const MOVEMENT_DIRECTION_THRESHOLD = 2;
const VELOCITY_STOP_THRESHOLD = 0.5;
const MOVEMENT_EPSILON = 0.0001;

// Vertical platform physics.
const GRAVITY_PER_SECOND = 1300;
const MAX_FALL_SPEED = 950;
const JUMP_VELOCITY = -450;
const MAX_JUMPS = 2;

// Combat and damage system.
const MAX_STOCKS = 3;
const ATTACK_DAMAGE = 8;
const KNOCK_BASE_SPEED = 240;
const KNOCK_DAMAGE_SCALE = 4.5;
const KNOCK_UP_RATIO = 0.55;
const ATTACK_DURATION_S = 0.45;
const HURT_DURATION_S = 0.35;
const INVINCIBLE_DURATION_S = 1.8;

// Input direction mapping used to calculate velocity/facing.
const DIRECTIONS = {
    left: { dx: -1, dy: 0, facing: 'left' },
    right: { dx: 1, dy: 0, facing: 'right' },
    none: { dx: 0, dy: 0, facing: 'none' }
};

// Load the level data once at server startup.
const LEVEL = loadMultiplayerLevel();
const PLAYER_TEMPLATE = findPlayerTemplate(LEVEL.sprites);
const GEM_TEMPLATE_BY_TYPE = buildGemTemplateMap(LEVEL.sprites);

// Heal item properties.
const HEAL_ITEM_WIDTH = 18; // tamaño del powerup de curación (cuadrado)
const HEAL_ITEM_HEIGHT = 18; // cantidad de curación que otorga el powerup
const HEAL_AMOUNT = 35; // cantidad de curación que otorga el powerup
const HEAL_RESPAWN_MS = 12000; // tiempo que tarda en reaparecer un powerup de curación después de ser recogido

// posibles puntos de aparicion
const HEAL_SPAWN_POINTS = [
    { x: 260, y: 392 },
    { x: 640, y: 302 },
    { x: 1020, y: 392 },
    { x: 430, y: 502 },
    { x: 850, y: 502 },
];
// Chance (per spawn slot) to turn a heal into a heal powerup (0.0 - 1.0)
const HEAL_POWERUP_PROBABILITY = 0.05;

// Main game server logic class.
// Tracks players, match state, environment movement and collision detection.
class GameLogic {
    constructor() {
        // Active players in the current match.
        // Active players in the current match.
        this.players = new Map();

        // Main loop tick counter used to update animation frames and track time.
        this.tickCounter = 0;

        // Join order is used for spawn assignment and ranking ties.
        this.nextJoinOrder = 0;

        // Gem IDs may be assigned as items spawn.
        this.nextGemId = 0;

        // Current phase of the game: 'waiting', 'playing', 'results', 'rest'.
        this.phase = 'waiting';
        this.lobbyEndsAt = null;
        this.winnerId = '';

        // Active gems/heal items on the map.
        this.gems = [];
        this.healRespawnTimeout = null; // control de reaparición de powerups de curación

        // State dirty flag for snapshot polling.
        this.initialStateDirty = true;

        // Rematch voting state.
        this.rematchPool = new Set();
        this.rematchLobbyEndsAt = null;

        // Players queued for removal after rematch decisions.
        this.kickQueue = [];

        // Runtime state copies for animated layers and zones.
        this.layerRuntimeStates = LEVEL.layers.map((layer) => ({
            x: layer.x,
            y: layer.y
        }));
        this.zoneRuntimeStates = LEVEL.zones.map((zone) => ({
            x: zone.x,
            y: zone.y
        }));
        this.zonePreviousRuntimeStates = LEVEL.zones.map((zone) => ({
            x: zone.x,
            y: zone.y
        }));
        this.pathMotionTimeSeconds = 0;

        this.pathRuntimeById = new Map();
        for (const path of LEVEL.paths) {
            const runtime = createPathRuntime(path);
            if (runtime) {
                this.pathRuntimeById.set(path.id, runtime);
            }
        }

        this.pathBindingRuntimes = LEVEL.pathBindings
            .filter((binding) => binding.enabled)
            .map((binding) => {
                const pathRuntime = this.pathRuntimeById.get(binding.pathId);
                if (!pathRuntime) {
                    return null;
                }
                const initial = this.getInitialTargetPosition(binding.targetType, binding.targetIndex);
                if (!initial) {
                    return null;
                }
                return {
                    binding,
                    pathRuntime,
                    initialX: initial.x,
                    initialY: initial.y
                };
            })
            .filter(Boolean);

        this.wallZoneIndices = classifyZoneIndices(['mur', 'wall'], LEVEL.zones);
        this.platformZoneIndices = classifyZoneIndices(['platform'], LEVEL.zones);
        this.deathZoneIndices = classifyZoneIndices(['death', 'mort', 'muerte'], LEVEL.zones);
    }

    // Add a player to the lobby or current match.
    // Returns the player state object or null if the match is full or already playing.
    addClient(id) {
        if (this.phase === 'playing') {
            return null;
        }
        if (this.players.size >= MAX_PLAYERS) {
            return null;
        }
        const spawn = this.getSpawnPosition(this.players.size);
        const idleAnimId = resolveAnimationIdByName('idle') || (PLAYER_TEMPLATE ? PLAYER_TEMPLATE.animationId : '');
        const player = {
            id,
            name: `Astronauta ${this.players.size + 1}`,
            x: spawn.x,
            y: spawn.y,
            width: PLAYER_WIDTH,
            height: PLAYER_HEIGHT,
            direction: 'none',
            facing: 'right',
            moving: false,
            grounded: false,
            jumpCount: 0,
            jumpPressedThisTick: false,
            attacking: false,
            attackVariant: 1,
            attackTimer: 0,
            hurtTimer: 0,
            invincibleTimer: 0,
            damage: 0,
            stocks: MAX_STOCKS,
            joinOrder: this.nextJoinOrder++,
            velocityX: 0,
            velocityY: 0,
            animationId: idleAnimId,
            frameIndex: resolveClipStartFrame(idleAnimId),
            flipX: false,
            flipY: false
        };
        // stats
        player.score = 0;
        player.gemsCollected = 0;
        this.players.set(id, player);
        this.initialStateDirty = true;

        if (this.phase === 'results') {
            this.startWaitingRoom();
            if (this.players.size >= 2 && this.lobbyEndsAt == null) {
                this.startCountdown();
            }
            return player;
        }

        if (this.phase === 'rest') {
            this.startWaitingRoom();
        } else if (this.phase === 'waiting') {
            if (this.players.size >= 2 && this.lobbyEndsAt == null) {
                this.startCountdown();
            }
        }

        return player;
    }

    // Remove a player from the match or lobby.
    // Also clears them from rematch voting state.
    removeClient(id) {
        this.rematchPool.delete(id);
        this.players.delete(id);
        this.initialStateDirty = true;
        if (this.players.size <= 0) {
            this.resetMatch();
            this.nextJoinOrder = 0;
            return;
        }
        if (this.phase === 'waiting' && this.players.size < 2) {
            // Cancel countdown until a second player joins again
            this.lobbyEndsAt = null;
        }

    }

    // Handle a message received from a client.
    // Parses JSON messages and updates player input, registration, or rematch requests.
    handleMessage(id, msg) {
        try {
            const obj = JSON.parse(msg);
            if (!obj || !obj.type) {
                return { stateChanged: false };
            }

            const player = this.players.get(id);
            if (!player) {
                return { stateChanged: false };
            }

            switch (obj.type) {
                case 'register':
                    {
                        const nextName = sanitizePlayerName(obj.playerName, player.name);
                        if (nextName !== player.name) {
                            const nameTaken = Array.from(this.players.entries()).some(
                                ([otherId, other]) => otherId !== id && other.name.toLowerCase() === nextName.toLowerCase()
                            );
                            if (nameTaken) {
                                return { stateChanged: false, rejection: { reason: 'name_taken', name: nextName } };
                            }
                            player.name = nextName;
                            this.initialStateDirty = true;
                            return { stateChanged: true, registered: true, name: nextName };
                        }
                    }
                    break;
                case 'direction':
                    player.direction = normalizeDirection(obj.value);
                    if (player.direction !== 'none') {
                        player.facing = DIRECTIONS[player.direction].facing;
                    }
                    break;
                case 'jump':
                    if (this.phase === 'playing') {
                        player.jumpPressedThisTick = true;
                    }
                    break;
                case 'attack':
                    if (this.phase === 'playing' && !player.attacking && player.hurtTimer <= 0 && player.stocks > 0) {
                        const variant = Math.max(1, Math.min(3, Number(obj.variant) || 1));
                        player.attacking = true;
                        player.attackVariant = variant;
                        player.attackTimer = ATTACK_DURATION_S;
                    }
                    break;
                case 'restartMatch':
                    if (this.phase === 'results') {
                        this.startWaitingRoom();
                        if (this.players.size >= 2 && this.lobbyEndsAt == null) {
                            this.startCountdown();
                        }
                        return { stateChanged: true };
                    }
                    break;
                default:
                    break;
            }
        } catch (_) {
        }
        return { stateChanged: false };
    }

    // Main server tick update.
    // Advances environment animation, processes player physics, handles game state transitions,
    // and detects win/lose conditions.
    updateGame(fps) {
        if (this.phase === 'results') {
            if (this.resultsEndsAt != null && Date.now() >= this.resultsEndsAt) {
                this.startWaitingRoom();
                if (this.players.size >= 2) {
                    this.startCountdown();
                }
            }
            return;
        }

        if (this.players.size <= 0) {
            return;
        }

        const safeFps = Math.max(1, fps || TARGET_FPS_FALLBACK);
        const dtSeconds = 1 / safeFps;
        this.tickCounter = (this.tickCounter + 1) % 1000000;

        this.advanceEnvironment(dtSeconds);

        if (this.phase === 'waiting') {
            if (this.players.size >= 2 && this.lobbyEndsAt != null && Date.now() >= this.lobbyEndsAt) {
                this.startMatch();
            }
            return;
        }

        if (this.phase !== 'playing') {
            return;
        }

        for (const player of this.players.values()) {
            if (player.stocks <= 0) {
                continue;
            }

            // Tick timers
            player.attackTimer = Math.max(0, player.attackTimer - dtSeconds);
            player.hurtTimer = Math.max(0, player.hurtTimer - dtSeconds);
            player.invincibleTimer = Math.max(0, player.invincibleTimer - dtSeconds);
            if (player.attackTimer <= 0) {
                player.attacking = false;
            }

            // Gravity
            player.velocityY = Math.min(player.velocityY + GRAVITY_PER_SECOND * dtSeconds, MAX_FALL_SPEED);

            // Jump
            if (player.jumpPressedThisTick) {
                player.jumpPressedThisTick = false;
                if (player.jumpCount < MAX_JUMPS) {
                    player.velocityY = JUMP_VELOCITY;
                    player.jumpCount++;
                    player.grounded = false;
                }
            }

            // Horizontal input (reduced control while hurt/knocked back)
            if (player.hurtTimer <= 0) {
                const direction = DIRECTIONS[player.direction] || DIRECTIONS.none;
                const airFactor = player.grounded ? 1 : HORIZONTAL_AIR_FACTOR;
                const targetVX = direction.dx * MOVE_SPEED_PER_SECOND * airFactor;
                const hasInput = direction.dx !== 0;
                const maxDelta = (hasInput ? NORMAL_ACCELERATION_PER_SECOND : NORMAL_DECELERATION_PER_SECOND) * dtSeconds;
                player.velocityX = approach(player.velocityX, targetVX, maxDelta);
            } else {
                // Decelerate knockback
                player.velocityX = approach(player.velocityX, 0, 350 * dtSeconds);
            }
            if (Math.abs(player.velocityX) < VELOCITY_STOP_THRESHOLD) {
                player.velocityX = 0;
            }

            // Facing from horizontal velocity
            if (player.velocityX < -MOVEMENT_DIRECTION_THRESHOLD) {
                player.facing = 'left';
                player.flipX = true;
            } else if (player.velocityX > MOVEMENT_DIRECTION_THRESHOLD) {
                player.facing = 'right';
                player.flipX = false;
            }

            // Move horizontally (world boundary clamp only)
            player.x = clamp(
                player.x + player.velocityX * dtSeconds,
                0,
                Math.max(0, LEVEL.worldWidth - player.width)
            );

            // Move vertically with one-way platform landing
            const prevBottom = player.y + player.height;
            player.y += player.velocityY * dtSeconds;
            const newBottom = player.y + player.height;
            player.grounded = false;

            if (player.velocityY >= 0) {
                for (const zi of this.platformZoneIndices) {
                    const zone = this.zoneRectAtIndex(zi);
                    if (player.x + player.width <= zone.left || player.x >= zone.right) {
                        continue;
                    }
                    if (prevBottom <= zone.top + 1 && newBottom >= zone.top) {
                        player.y = zone.top - player.height;
                        player.velocityY = 0;
                        player.grounded = true;
                        player.jumpCount = 0;
                        break;
                    }
                }
            }

            // Top boundary
            if (player.y < 0) {
                player.y = 0;
                if (player.velocityY < 0) {
                    player.velocityY = 0;
                }
            }

            // Ground probe: are we standing on a platform?
            if (!player.grounded) {
                const probeBottom = player.y + player.height + 2;
                for (const zi of this.platformZoneIndices) {
                    const zone = this.zoneRectAtIndex(zi);
                    if (player.x + player.width <= zone.left || player.x >= zone.right) {
                        continue;
                    }
                    if (probeBottom >= zone.top && player.y + player.height <= zone.top + 3) {
                        player.grounded = true;
                        player.jumpCount = 0;
                        break;
                    }
                }
            }

            // Death zone
            if (this.playerOverlapsAnyZone(player, this.deathZoneIndices)) {
                player.stocks = Math.max(0, player.stocks - 1);
                if (player.stocks > 0) {
                    this.respawnPlayer(player);
                }
            }

            // Attack hit detection
            if (player.attacking) {
                this.checkAttackHits(player);
            }

            // Animation & movement flag
            player.moving = Math.abs(player.velocityX) > MOVEMENT_DIRECTION_THRESHOLD && player.grounded;
            player.animationId = this.resolveSmashAnimationId(player);
            player.frameIndex = resolveAnimationFrame(player.animationId, this.tickCounter / safeFps);
            // Check for gem collection after movement/animation updated
            try {
                this.collectTouchedGems(player);
            } catch (ex) {
                // ignore
            }
        }

        // Win condition: only 1 (or 0) active players remaining
        const activePlayers = Array.from(this.players.values()).filter((p) => p.stocks > 0);
        if (this.players.size >= 2 && activePlayers.length <= 1) {
            this.finishMatch();
        }
    }

    // Check whether the attacker hit any other players during an active attack.
    // Applies damage, knockback, hurt state or stock loss on successful hits.
    checkAttackHits(attacker) {
        const clip = LEVEL.animationClips.get(attacker.animationId);
        const hitBoxes = activeHitBoxesForClip(clip, attacker.frameIndex);
        if (!hitBoxes || hitBoxes.length === 0) {
            return;
        }
        const attackRects = hitBoxes.map((hb) =>
            hitBoxRectAt(attacker.x, attacker.y, attacker.width, attacker.height, hb, attacker.flipX, attacker.flipY)
        );
        for (const other of this.players.values()) {
            if (other.id === attacker.id || other.stocks <= 0 || other.invincibleTimer > 0) {
                continue;
            }
            const otherRect = rectAt(other.x, other.y, other.width, other.height);
            let hit = false;
            for (const ar of attackRects) {
                if (rectsOverlap(ar, otherRect)) {
                    hit = true;
                    break;
                }
            }
            if (!hit) {
                continue;
            }
            const newDamage = other.damage + ATTACK_DAMAGE;
            if (newDamage > 100) {
                // This hit pushes damage over 100%: kill the player
                other.stocks = Math.max(0, other.stocks - 1);
                if (other.stocks > 0) {
                    this.respawnPlayer(other);
                } else {
                    other.hurtTimer = HURT_DURATION_S;
                    other.invincibleTimer = INVINCIBLE_DURATION_S;
                }
            } else {
                other.damage = newDamage;
                const knockSpeed = KNOCK_BASE_SPEED + other.damage * KNOCK_DAMAGE_SCALE;
                const dirX = attacker.flipX ? -1 : 1;
                other.velocityX = dirX * knockSpeed;
                other.velocityY = -knockSpeed * KNOCK_UP_RATIO;
                other.hurtTimer = HURT_DURATION_S;
                other.invincibleTimer = INVINCIBLE_DURATION_S;
                other.grounded = false;
            }
        }
    }

    // Choose the correct animation clip based on player state.
    resolveSmashAnimationId(player) {
        if (player.hurtTimer > 0) {
            return resolveAnimationIdByName('hurt') || (PLAYER_TEMPLATE ? PLAYER_TEMPLATE.animationId : '');
        }
        if (player.attacking) {
            return resolveAnimationIdByName(`attack${player.attackVariant}`) || (PLAYER_TEMPLATE ? PLAYER_TEMPLATE.animationId : '');
        }
        if (!player.grounded) {
            return resolveAnimationIdByName('jump') || (PLAYER_TEMPLATE ? PLAYER_TEMPLATE.animationId : '');
        }
        if (player.moving) {
            return resolveAnimationIdByName('move') || (PLAYER_TEMPLATE ? PLAYER_TEMPLATE.animationId : '');
        }
        return resolveAnimationIdByName('idle') || (PLAYER_TEMPLATE ? PLAYER_TEMPLATE.animationId : '');
    }

    // Start the rematch countdown if enough players request it.
    _checkRematchCountdown() {
        if (this.rematchPool.size >= 2 && this.rematchLobbyEndsAt == null) {
            this.rematchLobbyEndsAt = Date.now() + COUNTDOWN_DURATION_MS;
            this.resultsEndsAt = null; // cancel auto-reset once rematch is confirmed
            console.log(`Rematch countdown started: match begins in ${COUNTDOWN_DURATION_MS / 1000}s`);
        }
    }

    // Reset the lobby for a rematch, removing players who did not vote.
    _startRematchMatch() {
        // Kick players who did not press rematch
        for (const id of this.players.keys()) {
            if (!this.rematchPool.has(id)) {
                this.kickQueue.push(id);
            }
        }
        for (const id of this.kickQueue) {
            this.players.delete(id);
        }
        this.rematchPool.clear();
        this.rematchLobbyEndsAt = null;

        if (this.players.size === 0) {
            this.resetMatch();
            return;
        }

        // Reassign join orders sequentially to avoid gaps
        let order = 0;
        for (const player of this.players.values()) {
            player.joinOrder = order++;
        }
        this.nextJoinOrder = order;

        this.startWaitingRoom();
        if (this.players.size >= 2) {
            this.startCountdown();
        }
    }

    // Return and clear the list of players that should be removed from the room.
    consumeKickQueue() {
        const queue = this.kickQueue;
        this.kickQueue = [];
        return queue;
    }

    // Respawn a player after losing a stock.
    // Resets movement and combat state while granting temporary invincibility.
    respawnPlayer(player) {
        const spawn = this.getSpawnPosition(player.joinOrder % MAX_PLAYERS);
        player.x = spawn.x;
        player.y = spawn.y;
        player.direction = 'none';
        player.velocityX = 0;
        player.velocityY = 0;
        player.grounded = false;
        player.jumpCount = 0;
        player.attacking = false;
        player.attackTimer = 0;
        player.hurtTimer = 0;
        player.invincibleTimer = INVINCIBLE_DURATION_S;
        player.damage = 0;
        const idleAnimId = resolveAnimationIdByName('idle') || (PLAYER_TEMPLATE ? PLAYER_TEMPLATE.animationId : '');
        player.animationId = idleAnimId;
        player.frameIndex = resolveClipStartFrame(idleAnimId);
    }

    // Return the initial lobby snapshot once after the state changes.
    consumeSnapshotState() {
        if (!this.initialStateDirty) {
            return null;
        }
        this.initialStateDirty = false;
        return this.getSnapshotState();
    }

    // Build the lobby snapshot used by clients for match setup.
    getSnapshotState() {
        const players = Array.from(this.players.values()).sort(comparePlayers);
        return {
            level: LEVEL.levelName,
            players: players.map((player) => ({
                id: player.id,
                name: player.name,
                width: player.width,
                height: player.height,
                joinOrder: player.joinOrder
            })),
            gems: []
        };
    }

    // Build the full gameplay state for broadcast to all clients.
    getGameplayState() {
        const players = Array.from(this.players.values()).sort(comparePlayers);
        return {
            ...this.getGameplayStateBase(players),
            players: players.map((player) => ({
                ...this.serializeGameplayPlayer(player),
            })),
            gems: [],
        };
    }

    // Build a gameplay state tailored for a single player.
    // This can include the player's own state, other players, and optionally gems.
    getGameplayStateForPlayer(playerId, options = {}) {
        const includeOtherPlayers = options.includeOtherPlayers !== false;
        const includeGems = options.includeGems === true;
        const players = Array.from(this.players.values()).sort(comparePlayers);
        const selfPlayer = this.players.get(playerId);
        const state = {
            ...this.getGameplayStateBase(players),
            selfPlayer: selfPlayer ? this.serializeGameplayPlayer(selfPlayer) : null,
        };

        if (includeOtherPlayers) {
            state.otherPlayers = players
                .filter((player) => player.id !== playerId)
                .map((player) => this.serializeGameplayPlayer(player));
        }
        state.gems = includeGems ? this.gems.map((g) => ({
            id: g.id,
            type: g.type,
            x: round2(g.x),
            y: round2(g.y),
            width: g.width,
            height: g.height,
            value: g.value,
            visible: !!g.visible
        })) : [];

        return state;
    }

    // Return a combined snapshot and gameplay state.
    getFullState() {
        return {
            ...this.getSnapshotState(),
            ...this.getGameplayState()
        };
    }

    // Build the shared gameplay state fields.
    getGameplayStateBase(players) {
        const countdownSeconds = (this.phase === 'waiting' && this.lobbyEndsAt != null)
            ? Math.max(0, Math.ceil((this.lobbyEndsAt - Date.now()) / 1000))
            : 0;
        const resultsSeconds = this.phase === 'results' && this.resultsEndsAt != null
            ? Math.max(0, Math.ceil((this.resultsEndsAt - Date.now()) / 1000))
            : 0;
        const winner = this.winnerId ? this.players.get(this.winnerId) : players[0];

        return {
            tickCounter: this.tickCounter,
            phase: this.phase,
            countdownSeconds,
            resultsSeconds,
            remainingGems: 0,
            winnerId: winner ? winner.id : '',
            winnerName: winner ? winner.name : '',
            layerTransforms: this.layerRuntimeStates.map((layer, index) => ({
                index,
                x: round2(layer.x),
                y: round2(layer.y)
            })),
            zoneTransforms: this.zoneRuntimeStates.map((zone, index) => ({
                index,
                x: round2(zone.x),
                y: round2(zone.y)
            }))
        };
    }

    // Convert a player object into the serialized gameplay payload format.
    serializeGameplayPlayer(player) {
        return {
            id: player.id,
            x: round2(player.x),
            y: round2(player.y),
            damage: player.damage,
            stocks: player.stocks,
            direction: player.direction,
            facing: player.facing,
            moving: player.moving,
            grounded: player.grounded,
            attacking: player.attacking,
            attackVariant: player.attackVariant,
            hurtTimer: round2(player.hurtTimer),
            flipX: player.flipX,
        };
    }

    // Set game mode to waiting room and prepare the environment.
    startWaitingRoom() {
        this.phase = 'waiting';
        this.winnerId = '';
        this.lobbyEndsAt = null;
        this.resultsEndsAt = null;
        this.rematchPool.clear();
        this.rematchLobbyEndsAt = null;
        this.initialStateDirty = true;
        this.resetEnvironmentRuntime();
        this.positionPlayersForStart();
    }

    // Begin the match countdown; used when enough players are present.
    startCountdown() {
        this.lobbyEndsAt = Date.now() + COUNTDOWN_DURATION_MS;
        this.initialStateDirty = true;
        console.log(`Countdown started: match begins in ${COUNTDOWN_DURATION_MS / 1000}s`);
    }

    // Transition from waiting room into active gameplay.
    startMatch() {
        this.phase = 'playing';
        this.winnerId = '';
        this.lobbyEndsAt = null;
        this.resetEnvironmentRuntime();
        this.positionPlayersForStart();
        // Spawn gems (and occasional heal powerups) when the match starts
        try {
            this.spawnHealItems();
        } catch (ex) {
            // ignore spawn errors
        }
    }

    // End the current match and enter the results screen state.
    finishMatch() {
        this.phase = 'results';
        this.resultsEndsAt = Date.now() + RESULTS_DURATION_MS;
        const players = Array.from(this.players.values()).sort(comparePlayers);
        this.winnerId = players.length > 0 ? players[0].id : '';
        console.log(`Match finished. Results shown for ${RESULTS_DURATION_MS / 1000}s.`);
    }

    // Move the server into waiting room state while players remain.
    restartToWaitingRoom() {
        if (this.players.size <= 0) {
            this.resetMatch();
            return;
        }
        this.startWaitingRoom();
    }

    // Reset the server into a resting state with no active match.
    resetMatch() {
        this.lobbyEndsAt = null;
        this.resultsEndsAt = null;
        this.rematchPool.clear();
        this.rematchLobbyEndsAt = null;
        this.winnerId = '';
        this.gems = [];
        this.initialStateDirty = true;
        this.resetEnvironmentRuntime();
        console.log('Server back to REST — waiting for players.');
    }

    // Reset dynamic layer/zone runtime positions to the level default.
    resetEnvironmentRuntime() {
        this.pathMotionTimeSeconds = 0;
        this.layerRuntimeStates = LEVEL.layers.map((layer) => ({
            x: layer.x,
            y: layer.y
        }));
        this.zoneRuntimeStates = LEVEL.zones.map((zone) => ({
            x: zone.x,
            y: zone.y
        }));
        this.zonePreviousRuntimeStates = LEVEL.zones.map((zone) => ({
            x: zone.x,
            y: zone.y
        }));
    }

    // Update animated layer/zone movement based on path bindings.
    advanceEnvironment(dtSeconds) {
        for (let i = 0; i < this.zoneRuntimeStates.length; i++) {
            this.zonePreviousRuntimeStates[i].x = this.zoneRuntimeStates[i].x;
            this.zonePreviousRuntimeStates[i].y = this.zoneRuntimeStates[i].y;
        }

        this.pathMotionTimeSeconds += dtSeconds;
        for (const runtime of this.pathBindingRuntimes) {
            const progress = pathProgressAtTime(
                runtime.binding.behavior,
                runtime.binding.durationSeconds,
                this.pathMotionTimeSeconds
            );
            const sample = samplePathAtProgress(runtime.pathRuntime, progress);
            const targetX = runtime.binding.relativeToInitialPosition
                ? runtime.initialX + (sample.x - runtime.pathRuntime.firstPointX)
                : sample.x;
            const targetY = runtime.binding.relativeToInitialPosition
                ? runtime.initialY + (sample.y - runtime.pathRuntime.firstPointY)
                : sample.y;
            this.applyPathTarget(runtime.binding.targetType, runtime.binding.targetIndex, targetX, targetY);
        }
    }

    // Apply path-driven movement to layers or zones.
    applyPathTarget(targetType, targetIndex, x, y) {
        if (targetType === 'layer' && this.layerRuntimeStates[targetIndex]) {
            this.layerRuntimeStates[targetIndex].x = x;
            this.layerRuntimeStates[targetIndex].y = y;
            return;
        }
        if (targetType === 'zone' && this.zoneRuntimeStates[targetIndex]) {
            this.zoneRuntimeStates[targetIndex].x = x;
            this.zoneRuntimeStates[targetIndex].y = y;
        }
    }

    // Get the default starting position for a layer or zone target.
    getInitialTargetPosition(targetType, targetIndex) {
        if (targetType === 'layer' && LEVEL.layers[targetIndex]) {
            return { x: LEVEL.layers[targetIndex].x, y: LEVEL.layers[targetIndex].y };
        }
        if (targetType === 'zone' && LEVEL.zones[targetIndex]) {
            return { x: LEVEL.zones[targetIndex].x, y: LEVEL.zones[targetIndex].y };
        }
        return null;
    }

    // Reposition all players at the beginning of a match or waiting room.
    positionPlayersForStart() {
        const players = Array.from(this.players.values()).sort((a, b) => a.joinOrder - b.joinOrder);
        players.forEach((player, index) => {
            this.resetPlayerForMatch(player, index);
        });
    }

    // Reset all player input, movement, and combat state before match start.
    resetPlayerForMatch(player, index) {
        const spawn = this.getSpawnPosition(index);
        player.x = spawn.x;
        player.y = spawn.y;
        player.direction = 'none';
        player.facing = 'right';
        player.moving = false;
        player.grounded = false;
        player.jumpCount = 0;
        player.jumpPressedThisTick = false;
        player.attacking = false;
        player.attackVariant = 1;
        player.attackTimer = 0;
        player.hurtTimer = 0;
        player.invincibleTimer = 0;
        player.damage = 0;
        player.stocks = MAX_STOCKS;
        player.velocityX = 0;
        player.velocityY = 0;
        player.flipX = false;
        player.flipY = false;
        const idleAnimId = resolveAnimationIdByName('idle') || (PLAYER_TEMPLATE ? PLAYER_TEMPLATE.animationId : '');
        player.animationId = idleAnimId;
        player.frameIndex = resolveClipStartFrame(idleAnimId);
    }

    // Return one of the predefined spawn positions used for match start.
    getSpawnPosition(index) {
        // Spawns separados para 2-8 jugadores sobre la plataforma central.
        // Así evitamos que dos jugadores aparezcan exactamente encima del otro.
        const spawns = [
            { x: 330, y: 455 },
            { x: 430, y: 455 },
            { x: 530, y: 455 },
            { x: 630, y: 455 },
            { x: 730, y: 455 },
            { x: 830, y: 455 },
            { x: 930, y: 455 },
            { x: 1030, y: 455 },
        ];
        return spawns[index % spawns.length];
    }

    // Move the player while resolving collisions against wall zones.
    movePlayerWithWallCollisions(player, previousX, previousY, deltaX, deltaY) {
        let currentX = previousX;
        let currentY = previousY;
        let remainingX = deltaX;
        let remainingY = deltaY;

        for (let i = 0; i < MAX_COLLISION_SLIDE_ITERATIONS; i++) {
            if (Math.abs(remainingX) <= MOVEMENT_EPSILON &&
                Math.abs(remainingY) <= MOVEMENT_EPSILON) {
                break;
            }

            const targetX = currentX + remainingX;
            const targetY = currentY + remainingY;
            if (!this.wouldCollideBlocked(player, targetX, targetY)) {
                currentX = targetX;
                currentY = targetY;
                break;
            }

            const hitT = this.findCollisionTimeOnSegment(player, currentX, currentY, remainingX, remainingY);
            const safeT = clamp(hitT - COLLISION_TIME_BACKOFF, 0, 1);
            const probeT = clamp(hitT + COLLISION_TIME_BACKOFF, 0, 1);

            const segmentStartX = currentX;
            const segmentStartY = currentY;
            currentX = segmentStartX + remainingX * safeT;
            currentY = segmentStartY + remainingY * safeT;

            const probeX = segmentStartX + remainingX * probeT;
            const probeY = segmentStartY + remainingY * probeT;
            const normal = this.estimateCollisionNormalAt(player, probeX, probeY, remainingX, remainingY);

            const remainingScale = Math.max(0, 1 - safeT);
            let slideX = remainingX * remainingScale;
            let slideY = remainingY * remainingScale;
            const intoWall = slideX * normal.x + slideY * normal.y;
            if (intoWall < 0) {
                slideX -= intoWall * normal.x;
                slideY -= intoWall * normal.y;
            }

            remainingX = slideX;
            remainingY = slideY;
        }

        player.x = currentX;
        player.y = currentY;
        if (this.wouldCollideBlocked(player, player.x, player.y)) {
            player.x = previousX;
            player.y = previousY;
            this.resolveWallPenetration(player);
        }
    }

    // Push the player out of a wall if they become embedded in one.
    resolveWallPenetration(player) {
        if (!this.wouldCollideBlocked(player, player.x, player.y)) {
            return;
        }

        for (const zoneIndex of this.wallZoneIndices) {
            if (!this.collidesWithZoneAt(player, zoneIndex, player.x, player.y)) {
                continue;
            }

            const zoneRect = this.zoneRectAtIndex(zoneIndex);
            const playerRect = rectAt(player.x, player.y, player.width, player.height);

            const penLeft = playerRect.right - zoneRect.left;
            const penRight = zoneRect.right - playerRect.left;
            const penTop = playerRect.bottom - zoneRect.top;
            const penBottom = zoneRect.bottom - playerRect.top;

            let minPen = penLeft;
            let pushX = -penLeft;
            let pushY = 0;

            if (penRight < minPen) {
                minPen = penRight;
                pushX = penRight;
                pushY = 0;
            }
            if (penTop < minPen) {
                minPen = penTop;
                pushX = 0;
                pushY = -penTop;
            }
            if (penBottom < minPen) {
                minPen = penBottom;
                pushX = 0;
                pushY = penBottom;
            }

            player.x += pushX;
            player.y += pushY;
            player.x = clamp(player.x, 0, Math.max(0, LEVEL.worldWidth - player.width));
            player.y = clamp(player.y, 0, Math.max(0, LEVEL.worldHeight - player.height));

            if (!this.wouldCollideBlocked(player, player.x, player.y)) {
                return;
            }
        }
    }

    // If a moving wall is carrying the player, move the player along with it.
    applyMovingWallCarry(player) {
        let bestDeltaMagnitudeSq = 0;
        let carryX = 0;
        let carryY = 0;

        for (const zoneIndex of this.wallZoneIndices) {
            if (!this.collidesWithZoneAt(player, zoneIndex, player.x, player.y)) {
                continue;
            }

            const deltaX = this.zoneDeltaX(zoneIndex);
            const deltaY = this.zoneDeltaY(zoneIndex);
            if (Math.abs(deltaX) <= MOVEMENT_EPSILON &&
                Math.abs(deltaY) <= MOVEMENT_EPSILON) {
                continue;
            }

            const candidateX = clamp(
                player.x + deltaX,
                0,
                Math.max(0, LEVEL.worldWidth - player.width)
            );
            const candidateY = clamp(
                player.y + deltaY,
                0,
                Math.max(0, LEVEL.worldHeight - player.height)
            );

            const stillCollides = this.collidesWithZoneAt(player, zoneIndex, candidateX, candidateY);
            if (stillCollides) {
                continue;
            }

            const deltaMagnitudeSq = deltaX * deltaX + deltaY * deltaY;
            if (deltaMagnitudeSq > bestDeltaMagnitudeSq) {
                bestDeltaMagnitudeSq = deltaMagnitudeSq;
                carryX = candidateX - player.x;
                carryY = candidateY - player.y;
            }
        }

        if (bestDeltaMagnitudeSq > 0) {
            player.x += carryX;
            player.y += carryY;
        }
    }

    // Estimate the point along a movement segment where collision first occurs.
    findCollisionTimeOnSegment(player, startX, startY, deltaX, deltaY) {
        if (this.wouldCollideBlocked(player, startX, startY)) {
            return 0;
        }
        const distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
        if (distance <= MOVEMENT_EPSILON) {
            return 1;
        }

        const probeCount = Math.max(1, Math.ceil(distance / COLLISION_PROBE_SPACING));
        let low = 0;
        let high = 1;
        let hasCollision = false;
        for (let i = 1; i <= probeCount; i++) {
            const t = i / probeCount;
            const sampleX = startX + deltaX * t;
            const sampleY = startY + deltaY * t;
            if (this.wouldCollideBlocked(player, sampleX, sampleY)) {
                high = t;
                hasCollision = true;
                break;
            }
            low = t;
        }

        if (!hasCollision) {
            return 1;
        }

        for (let i = 0; i < COLLISION_SWEEP_ITERATIONS; i++) {
            const mid = (low + high) * 0.5;
            const midX = startX + deltaX * mid;
            const midY = startY + deltaY * mid;
            if (this.wouldCollideBlocked(player, midX, midY)) {
                high = mid;
            } else {
                low = mid;
            }
        }
        return high;
    }

    // Estimate the collision normal for a wall contact point.
    // Used to slide the player along surfaces instead of fully stopping.
    estimateCollisionNormalAt(player, x, y, movementX, movementY) {
        const playerRect = rectAt(x, y, player.width, player.height);
        let bestScore = Number.POSITIVE_INFINITY;
        let bestNormalX = 0;
        let bestNormalY = 0;

        for (const zoneIndex of this.wallZoneIndices) {
            if (!this.collidesWithZoneAt(player, zoneIndex, x, y)) {
                continue;
            }

            const zoneRect = this.zoneRectAtIndex(zoneIndex);
            const relativeX = movementX - this.zoneDeltaX(zoneIndex);
            const relativeY = movementY - this.zoneDeltaY(zoneIndex);
            const relativeSpeedSq = relativeX * relativeX + relativeY * relativeY;
            const hasRelativeMotion = relativeSpeedSq > MOVEMENT_EPSILON * MOVEMENT_EPSILON;

            const consider = (penetration, normalX, normalY) => {
                if (!Number.isFinite(penetration) || penetration <= MOVEMENT_EPSILON) {
                    return;
                }
                let score = penetration;
                if (hasRelativeMotion) {
                    const relativeDot = relativeX * normalX + relativeY * normalY;
                    if (relativeDot >= 0) {
                        score += 1000000;
                    }
                }
                if (score < bestScore) {
                    bestScore = score;
                    bestNormalX = normalX;
                    bestNormalY = normalY;
                }
            };

            consider(playerRect.right - zoneRect.left, -1, 0);
            consider(zoneRect.right - playerRect.left, 1, 0);
            consider(playerRect.bottom - zoneRect.top, 0, -1);
            consider(zoneRect.bottom - playerRect.top, 0, 1);
        }

        if (Number.isFinite(bestScore)) {
            return { x: bestNormalX, y: bestNormalY };
        }

        const moveLen = Math.sqrt(movementX * movementX + movementY * movementY);
        if (moveLen > MOVEMENT_EPSILON) {
            return { x: -movementX / moveLen, y: -movementY / moveLen };
        }
        return { x: 0, y: -1 };
    }

    // Check whether the player touched any gems or heal items.
    // Applies item effects and removes collected items from the map.
    // detecta si un jugador toca la cura
    collectTouchedGems(player) {
        const remainingGems = [];

        for (const gem of this.gems) {
            let collected = false;

            // comprobamos la colision entre el jugador y la cura, si hay colision aplicamos el efecto de la cura al jugador y no añadimos la cura a remainingGems, lo que hace que desaparezca del mapa
            if (
                rectsOverlap(
                    this.playerCollisionRect(player), 
                    this.gemCollisionRect(gem)
                )
            ) {
                const t = String(gem.type || '').toLowerCase();

                if (t.includes('heal')) {
                    player.damage = Math.max(0, player.damage - HEAL_AMOUNT); //aplicamos la cura
                    player.hurtTimer = 0;
                    player.gemsCollected += 1;
                    collected = true;
                }
            }

            if (!collected) {
                remainingGems.push(gem);
            }
        }

        this.gems = remainingGems; // eliminamos las curas recogidas del mapa

        if (
            this.gems.length === 0 &&
            this.phase === 'playing' &&
            !this.healRespawnTimeout
        ) {
            this.healRespawnTimeout = setTimeout(() => { // reaparece 
                this.spawnHealItems();
                this.healRespawnTimeout = null;
            }, HEAL_RESPAWN_MS);
        }
    }

    // Spawn a heal item on a random heal spawn point.
    // This is currently the only active item type in the match.
    // creamos la cura 
    spawnHealItems() {
        const point =
            HEAL_SPAWN_POINTS[
                Math.floor(Math.random() * HEAL_SPAWN_POINTS.length) // HEAL_SPAWN_POINTS.length
            ];

        // lo que recibe el cliente 
        this.gems = [
            {
                id: 'heal_001',
                type: 'heal',
                x: point.x,
                y: point.y,
                width: HEAL_ITEM_WIDTH,
                height: HEAL_ITEM_HEIGHT,
                value: HEAL_AMOUNT
            }
        ];
    }

    // Check whether the player overlaps any of the given zones.
    playerOverlapsAnyZone(player, zoneIndices) {
        for (const zoneIndex of zoneIndices) {
            if (this.collidesWithZoneAt(player, zoneIndex, player.x, player.y)) {
                return true;
            }
        }
        return false;
    }

    // Detect collision between the player and a single zone at a proposed position.
    collidesWithZoneAt(player, zoneIndex, x, y) {
        const zoneRect = this.zoneRectAtIndex(zoneIndex);
        for (const hitBoxRect of this.playerHitBoxRectsAt(player, x, y)) {
            if (rectsOverlap(hitBoxRect, zoneRect)) {
                return true;
            }
        }
        return false;
    }

    // Determine whether placing the player at the position would intersect any wall zone.
    wouldCollideBlocked(player, x, y) {
        for (const zoneIndex of this.wallZoneIndices) {
            const zoneRect = this.zoneRectAtIndex(zoneIndex);
            for (const hitBoxRect of this.playerHitBoxRectsAt(player, x, y)) {
                if (rectsOverlap(hitBoxRect, zoneRect)) {
                    return true;
                }
            }
        }
        return false;
    }

    // Build a rectangle for a zone using current runtime transform.
    zoneRectAtIndex(zoneIndex) {
        const zone = LEVEL.zones[zoneIndex];
        const runtime = this.zoneRuntimeStates[zoneIndex] || zone;
        return rectAt(runtime.x, runtime.y, zone.width, zone.height);
    }

    // Return how far a zone moved horizontally during the last tick.
    zoneDeltaX(zoneIndex) {
        const current = this.zoneRuntimeStates[zoneIndex];
        const previous = this.zonePreviousRuntimeStates[zoneIndex];
        if (!current || !previous) {
            return 0;
        }
        return current.x - previous.x;
    }

    // Return how far a zone moved vertically during the last tick.
    zoneDeltaY(zoneIndex) {
        const current = this.zoneRuntimeStates[zoneIndex];
        const previous = this.zonePreviousRuntimeStates[zoneIndex];
        if (!current || !previous) {
            return 0;
        }
        return current.y - previous.y;
    }

    // Create a broad hitbox for the player using active frame hitboxes.
    playerCollisionRect(player) {
        const hitBoxes = this.playerHitBoxRectsAt(player, player.x, player.y);
        return unionRects(hitBoxes, rectAt(player.x, player.y, player.width, player.height));
    }

    // Get the active hitboxes for a player at a given position and animation frame.
    playerHitBoxRectsAt(player, x, y) {
        const clip = LEVEL.animationClips.get(player.animationId);
        const hitBoxes = activeHitBoxesForClip(clip, player.frameIndex);
        if (!hitBoxes || hitBoxes.length <= 0) {
            return [rectAt(x, y, player.width, player.height)];
        }
        return hitBoxes.map((hitBox) =>
            hitBoxRectAt(x, y, player.width, player.height, hitBox, player.flipX, player.flipY)
        );
    }

    // Calculate the gem's collision bounds from its animation hitboxes.
    gemCollisionRect(gem) {
        const template = GEM_TEMPLATE_BY_TYPE.get(gem.type);
        const clip = template ? LEVEL.animationClips.get(template.animationId) : null;
        const frameIndex = resolveAnimationFrame(template ? template.animationId : '', this.tickCounter / TARGET_FPS_FALLBACK);
        const hitBoxes = activeHitBoxesForClip(clip, frameIndex);
        if (!hitBoxes || hitBoxes.length <= 0) {
            return rectAt(gem.x, gem.y, gem.width, gem.height);
        }
        const rects = hitBoxes.map((hitBox) =>
            hitBoxRectAt(gem.x, gem.y, gem.width, gem.height, hitBox, false, false)
        );
        return unionRects(rects, rectAt(gem.x, gem.y, gem.width, gem.height));
    }
}

// Build a runtime descriptor for a path so we can sample positions along it.
function createPathRuntime(path) {
    if (!path || !Array.isArray(path.points) || path.points.length < 2) {
        return null;
    }

    const segments = [];
    let totalLength = 0;
    for (let i = 1; i < path.points.length; i++) {
        const a = path.points[i - 1];
        const b = path.points[i];
        const dx = b.x - a.x;
        const dy = b.y - a.y;
        const length = Math.sqrt(dx * dx + dy * dy);
        if (length <= 0) {
            continue;
        }
        segments.push({
            ax: a.x,
            ay: a.y,
            bx: b.x,
            by: b.y,
            length,
            startLength: totalLength,
            endLength: totalLength + length
        });
        totalLength += length;
    }

    if (segments.length <= 0 || totalLength <= 0) {
        return null;
    }

    return {
        firstPointX: path.points[0].x,
        firstPointY: path.points[0].y,
        totalLength,
        segments
    };
}

// Sample a position along a precomputed path at a normalized progress value.
function samplePathAtProgress(pathRuntime, progress) {
    if (!pathRuntime) {
        return { x: 0, y: 0 };
    }

    const clamped = clamp(progress, 0, 1);
    const targetLength = clamped * pathRuntime.totalLength;
    for (const segment of pathRuntime.segments) {
        if (targetLength <= segment.endLength) {
            const localLength = targetLength - segment.startLength;
            const alpha = segment.length <= 0 ? 0 : localLength / segment.length;
            return {
                x: lerp(segment.ax, segment.bx, alpha),
                y: lerp(segment.ay, segment.by, alpha)
            };
        }
    }

    const last = pathRuntime.segments[pathRuntime.segments.length - 1];
    return { x: last.bx, y: last.by };
}

// Convert elapsed time into a normalized path progress value depending on the path behavior.
function pathProgressAtTime(behavior, durationSeconds, timeSeconds) {
    if (!Number.isFinite(durationSeconds) || durationSeconds <= 0) {
        return 0;
    }

    const t = Math.max(0, timeSeconds);
    const normalizedBehavior = String(behavior || '').trim().toLowerCase();
    if (normalizedBehavior === 'ping_pong' || normalizedBehavior === 'pingpong') {
        const cycle = durationSeconds * 2;
        const cycleTime = t % cycle;
        if (cycleTime <= durationSeconds) {
            return cycleTime / durationSeconds;
        }
        return 1 - ((cycleTime - durationSeconds) / durationSeconds);
    }
    if (normalizedBehavior === 'once') {
        return clamp(t / durationSeconds, 0, 1);
    }
    return (t % durationSeconds) / durationSeconds;
}

// Identify zone indices whose name or type matches any of the provided tokens.
function classifyZoneIndices(tokens, zones) {
    const indices = [];
    for (let i = 0; i < zones.length; i++) {
        const zone = zones[i];
        const type = normalize(zone.type);
        const name = normalize(zone.name);
        if (containsAny(type, tokens) || containsAny(name, tokens)) {
            indices.push(i);
        }
    }
    return indices;
}

// Determine a facing direction string from directional inputs.
function resolveFacing(previousFacing, up, down, left, right) {
    if (up && left) {
        return 'upLeft';
    }
    if (up && right) {
        return 'upRight';
    }
    if (down && left) {
        return 'downLeft';
    }
    if (down && right) {
        return 'downRight';
    }
    if (up) {
        return 'up';
    }
    if (down) {
        return 'down';
    }
    if (left) {
        return 'left';
    }
    if (right) {
        return 'right';
    }
    return previousFacing || 'down';
}

// Compare players for ranking in lobby and end-of-match screens.
function comparePlayers(a, b) {
    // More stocks = better rank
    if (b.stocks !== a.stocks) return b.stocks - a.stocks;
    // Less damage = better rank
    if (a.damage !== b.damage) return a.damage - b.damage;
    return a.joinOrder - b.joinOrder;
}

// Ensure a player name is safe, trimmed, and no longer than the allowed length.
function sanitizePlayerName(value, fallback) {
    const name = String(value || '').replace(/\s+/g, ' ').trim();
    if (!name) {
        return fallback;
    }
    return name.substring(0, 18);
}

// Find a representative player sprite template from the level sprite list.
function findPlayerTemplate(sprites) {
    for (const sprite of sprites) {
        const type = normalize(sprite.type);
        const name = normalize(sprite.name);
        if (containsAny(type, ['player', 'hero', 'heroi', 'foxy', 'character']) ||
            containsAny(name, ['player', 'hero', 'heroi', 'foxy', 'character'])) {
            return sprite;
        }
    }
    return sprites[0] || null;
}

// Build lookup table for gem sprite templates by type.
function buildGemTemplateMap(sprites) {
    const map = new Map();
    for (const sprite of sprites) {
        const type = normalize(sprite.type);
        if (type.includes('gem purple')) {
            map.set('purple', sprite);
        } else if (type.includes('gem yellow')) {
            map.set('yellow', sprite);
        } else if (type.includes('gem green')) {
            map.set('green', sprite);
        } else if (type.includes('gem blue')) {
            map.set('blue', sprite);
        }
    }
    return map;
}

// Find an animation clip ID by its name.
function resolveAnimationIdByName(name) {
    const normalized = normalize(name);
    for (const clip of LEVEL.animationClips.values()) {
        if (normalize(clip.name) === normalized) {
            return clip.id;
        }
    }
    return null;
}

// Compute the current animation frame for a clip based on elapsed time.
function resolveAnimationFrame(animationId, elapsedSeconds) {
    const clip = LEVEL.animationClips.get(animationId);
    if (!clip) {
        return 0;
    }
    const start = Math.max(0, clip.startFrame);
    const end = Math.max(start, clip.endFrame);
    const span = Math.max(1, end - start + 1);
    const ticks = Math.floor(Math.max(0, elapsedSeconds) * clip.fps);
    const offset = clip.loop ? positiveMod(ticks, span) : Math.min(ticks, span - 1);
    return start + offset;
}

// Get the first frame index for an animation clip when the animation starts.
function resolveClipStartFrame(animationId) {
    const clip = LEVEL.animationClips.get(animationId);
    return clip ? Math.max(0, clip.startFrame) : 0;
}

// Return the active hitboxes for a clip at a frame, preferring frame-specific rigs.
function activeHitBoxesForClip(clip, frameIndex) {
    if (!clip) {
        return null;
    }
    const frameRig = clip.frameRigs.get(frameIndex);
    if (frameRig && frameRig.hitBoxes.length > 0) {
        return frameRig.hitBoxes;
    }
    if (clip.hitBoxes.length > 0) {
        return clip.hitBoxes;
    }
    return null;
}

// Convert a normalized hitbox into world-space rectangle coordinates.
function hitBoxRectAt(x, y, width, height, hitBox, flipX, flipY) {
    let normalizedX = hitBox.x;
    let normalizedY = hitBox.y;
    if (flipX) {
        normalizedX = 1 - hitBox.x - hitBox.width;
    }
    if (flipY) {
        normalizedY = 1 - hitBox.y - hitBox.height;
    }
    return rectAt(
        x + normalizedX * width,
        y + normalizedY * height,
        hitBox.width * width,
        hitBox.height * height
    );
}

// Combine multiple rectangles into a single bounding box.
function unionRects(rects, fallback) {
    if (!rects || rects.length <= 0) {
        return fallback;
    }
    let minLeft = Number.POSITIVE_INFINITY;
    let minTop = Number.POSITIVE_INFINITY;
    let maxRight = Number.NEGATIVE_INFINITY;
    let maxBottom = Number.NEGATIVE_INFINITY;
    for (const rect of rects) {
        minLeft = Math.min(minLeft, rect.left);
        minTop = Math.min(minTop, rect.top);
        maxRight = Math.max(maxRight, rect.right);
        maxBottom = Math.max(maxBottom, rect.bottom);
    }
    if (!Number.isFinite(minLeft) || !Number.isFinite(minTop) ||
        !Number.isFinite(maxRight) || !Number.isFinite(maxBottom)) {
        return fallback;
    }
    return rectAt(minLeft, minTop, maxRight - minLeft, maxBottom - minTop);
}

// Return a non-negative modulus value.
function positiveMod(value, divisor) {
    const mod = value % divisor;
    return mod < 0 ? mod + divisor : mod;
}

// Normalize direction strings into valid movement commands.
function normalizeDirection(value) {
    const direction = String(value || '').trim();
    return Object.prototype.hasOwnProperty.call(DIRECTIONS, direction)
        ? direction
        : 'none';
}

// Create a rectangle object from coordinates and size.
function rectAt(x, y, width, height) {
    return {
        left: x,
        top: y,
        right: x + width,
        bottom: y + height,
        width,
        height
    };
}

// Check whether two axis-aligned rectangles overlap.
function rectsOverlap(a, b) {
    return a.left < b.right &&
        a.right > b.left &&
        a.top < b.bottom &&
        a.bottom > b.top;
}

// Move a value toward a target by at most maxDelta.
function approach(current, target, maxDelta) {
    if (current < target) {
        return Math.min(current + maxDelta, target);
    }
    if (current > target) {
        return Math.max(current - maxDelta, target);
    }
    return target;
}

// Return true if the given text contains any of the needle substrings.
function containsAny(value, needles) {
    for (const needle of needles) {
        if (needle && value.includes(needle)) {
            return true;
        }
    }
    return false;
}

// Convert a value to normalized lowercase text.
function normalize(value) {
    return String(value || '').trim().toLowerCase();
}

// Clamp a number between a minimum and maximum.
function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
}

// Linear interpolation between two values.
function lerp(from, to, alpha) {
    return from + (to - from) * alpha;
}

// Round a number to two decimal places.
function round2(value) {
    return Math.round(value * 100) / 100;
}

// Shuffle an array in place using Fisher-Yates.
function shuffle(values) {
    for (let i = values.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        const temp = values[i];
        values[i] = values[j];
        values[j] = temp;
    }
    return values;
}

module.exports = GameLogic;
