import { Rng } from '../core/Rng';
import type { EnemyKind, WaveDef } from '../levels/LevelConfig';
import { CrowdSystem, type Lane } from './CrowdSystem';
import { FX, FxQueue, MAX_ENEMIES, TRACK_HALF, clamp } from './constants';

export const EnemyState = { Dead: 0, Idle: 1, March: 2, Fight: 3, Dying: 4 } as const;
export const KIND_INDEX: Record<EnemyKind, number> = { grunt: 0, brute: 1, giant: 2, turret: 3 };

export interface EnemyStats {
  hp: number;
  /** Melee damage per second (turret: damage per shot). */
  dps: number;
  speed: number;
  radius: number;
  score: number;
  scale: number;
}

export const ENEMY_STATS: readonly EnemyStats[] = [
  { hp: 11, dps: 4, speed: 2.8, radius: 0.34, score: 7, scale: 1 },
  { hp: 80, dps: 16, speed: 2.0, radius: 0.55, score: 30, scale: 1.25 },
  { hp: 420, dps: 40, speed: 1.4, radius: 1.25, score: 120, scale: 2.7 },
  { hp: 130, dps: 18, speed: 0, radius: 0.75, score: 50, scale: 1 },
];

const AGGRO = 30;
const TURRET_RANGE = 15;
const TURRET_INTERVAL = 1.5;
const MAX_BOLTS = 24;

/** Red army: melee robots that march on the cannon, plus static turrets. */
export class EnemySystem {
  readonly cap = MAX_ENEMIES;
  readonly x = new Float32Array(MAX_ENEMIES);
  readonly z = new Float32Array(MAX_ENEMIES);
  readonly hp = new Float32Array(MAX_ENEMIES);
  readonly maxHp = new Float32Array(MAX_ENEMIES);
  readonly dps = new Float32Array(MAX_ENEMIES);
  readonly kind = new Uint8Array(MAX_ENEMIES);
  readonly state = new Uint8Array(MAX_ENEMIES);
  readonly t = new Float32Array(MAX_ENEMIES);
  readonly flash = new Float32Array(MAX_ENEMIES);
  readonly phase = new Float32Array(MAX_ENEMIES);
  /** Blue agents attacking this enemy this tick / last tick. */
  readonly attackers = new Uint16Array(MAX_ENEMIES);
  readonly attackersPrev = new Uint16Array(MAX_ENEMIES);
  private readonly cd = new Float32Array(MAX_ENEMIES);

  // turret bolts in flight
  readonly boltX = new Float32Array(MAX_BOLTS);
  readonly boltZ = new Float32Array(MAX_BOLTS);
  readonly boltSX = new Float32Array(MAX_BOLTS);
  readonly boltSZ = new Float32Array(MAX_BOLTS);
  readonly boltTX = new Float32Array(MAX_BOLTS);
  readonly boltTZ = new Float32Array(MAX_BOLTS);
  readonly boltT = new Float32Array(MAX_BOLTS);
  readonly boltDmg = new Float32Array(MAX_BOLTS);
  readonly boltLive = new Uint8Array(MAX_BOLTS);
  readonly boltCap = MAX_BOLTS;

  alive = 0;
  killed = 0;
  score = 0;
  /** z of the closest living enemy that should hold the cannon back (Infinity = none). */
  blockerZ = Infinity;
  /** Damage dealt to the cannon this tick. */
  cannonDamage = 0;

  private nextWave = 0;
  private waves: WaveDef[] = [];

  constructor(private readonly rng: Rng, private hpScale = 1, private dmgScale = 1) {}

  setWaves(waves: readonly WaveDef[]): void {
    this.waves = [...waves].sort((a, b) => a.z - b.z);
    this.nextWave = 0;
  }

  spawn(kind: EnemyKind, x: number, z: number, aggro = false): number {
    for (let i = 0; i < this.cap; i++) {
      if (this.state[i] !== EnemyState.Dead) continue;
      const k = KIND_INDEX[kind];
      const stats = ENEMY_STATS[k]!;
      this.x[i] = clamp(x, -TRACK_HALF + stats.radius, TRACK_HALF - stats.radius);
      this.z[i] = z;
      this.kind[i] = k;
      this.hp[i] = this.maxHp[i] = stats.hp * this.hpScale;
      this.dps[i] = stats.dps * this.dmgScale;
      this.state[i] = aggro && stats.speed > 0 ? EnemyState.March : EnemyState.Idle;
      this.t[i] = 0;
      this.flash[i] = 0;
      this.attackers[i] = this.attackersPrev[i] = 0;
      this.phase[i] = this.rng.range(0, Math.PI * 2);
      this.cd[i] = this.rng.range(0.5, TURRET_INTERVAL);
      this.alive++;
      return i;
    }
    return -1;
  }

  private spawnWave(w: WaveDef): boolean {
    if (this.cap - this.alive < w.count + 8 && this.alive > 0) return false;
    const stats = ENEMY_STATS[KIND_INDEX[w.kind]]!;
    const gap = stats.radius * 2.5;
    const cols = Math.max(1, Math.min(Math.ceil(Math.sqrt(w.count * 1.8)), Math.floor((TRACK_HALF * 2 - 1) / gap)));
    for (let k = 0; k < w.count; k++) {
      const col = k % cols;
      const row = Math.floor(k / cols);
      const inRow = Math.min(cols, w.count - row * cols);
      this.spawn(w.kind, w.x + (col - (inRow - 1) / 2) * gap, w.z + row * gap);
    }
    return true;
  }

  isAlive(i: number): boolean {
    const s = this.state[i];
    return s === EnemyState.Idle || s === EnemyState.March || s === EnemyState.Fight;
  }

  /** Returns true when the hit killed the enemy. */
  hit(i: number, dmg: number, fx: FxQueue): boolean {
    if (!this.isAlive(i)) return false;
    this.hp[i] -= dmg;
    if (this.flash[i]! < 0.05) this.flash[i] = 1;
    if (this.hp[i]! > 0) return false;
    this.state[i] = EnemyState.Dying;
    this.t[i] = 0;
    this.alive--;
    this.killed++;
    this.score += ENEMY_STATS[this.kind[i]!]!.score;
    fx.push(FX.EnemyDie, this.x[i]!, this.z[i]!, this.kind[i]!);
    return true;
  }

  killAll(fx: FxQueue): void {
    for (let i = 0; i < this.cap; i++) if (this.isAlive(i)) this.hit(i, Infinity, fx);
  }

  update(dt: number, cannonX: number, cannonZ: number, crowd: CrowdSystem, lanes: readonly Lane[], fx: FxQueue): void {
    while (this.nextWave < this.waves.length && this.waves[this.nextWave]!.z < cannonZ + 62) {
      if (!this.spawnWave(this.waves[this.nextWave]!)) break;
      this.nextWave++;
    }
    this.blockerZ = Infinity;
    this.cannonDamage = 0;
    for (let i = 0; i < this.cap; i++) {
      const s = this.state[i]!;
      if (s === EnemyState.Dead) continue;
      this.t[i] += dt;
      if (this.flash[i]! > 0) this.flash[i] = Math.max(0, this.flash[i]! - dt * 6);
      if (s === EnemyState.Dying) {
        if (this.t[i]! > 0.6) this.state[i] = EnemyState.Dead;
        continue;
      }
      const k = this.kind[i]!;
      const stats = ENEMY_STATS[k]!;
      const engaged = this.attackers[i]! > 0;
      this.attackersPrev[i] = this.attackers[i]!;
      this.attackers[i] = 0;
      const ahead = this.z[i]! - cannonZ;
      if (k === 3) {
        // turret: holds the cannon at a distance and shells whatever is in range
        if (ahead < 9) this.blockerZ = Math.min(this.blockerZ, this.z[i]! + 1.5);
        this.cd[i] -= dt;
        if (this.cd[i]! <= 0 && ahead < TURRET_RANGE + 4) {
          this.cd[i] = TURRET_INTERVAL;
          this.fireBolt(i, cannonX, cannonZ, crowd, fx);
        }
        continue;
      }
      if (s === EnemyState.Idle && ahead < AGGRO) this.state[i] = EnemyState.March;
      if (this.state[i] === EnemyState.Idle) continue;
      if (ahead <= 1.5) {
        // reached the cannon: hammer it
        this.state[i] = EnemyState.Fight;
        this.cannonDamage += this.dps[i]! * 0.4 * dt;
        this.blockerZ = Math.min(this.blockerZ, this.z[i]!);
        continue;
      }
      this.state[i] = engaged ? EnemyState.Fight : EnemyState.March;
      if (!engaged) {
        this.z[i] -= stats.speed * dt;
        let tx = this.x[i]!;
        for (let l = 0; l < lanes.length; l++) {
          const lane = lanes[l]!;
          if (this.z[i]! > lane.z0 - 1 && this.z[i]! < lane.z1 + 6) tx = clamp(tx, lane.x0 + stats.radius, lane.x1 - stats.radius);
        }
        this.x[i] += clamp((tx - this.x[i]!) * 4, -3, 3) * dt;
      }
      if (ahead < 11) this.blockerZ = Math.min(this.blockerZ, this.z[i]!);
    }
    this.updateBolts(dt, cannonX, cannonZ, crowd, fx);
  }

  private fireBolt(i: number, cannonX: number, cannonZ: number, crowd: CrowdSystem, fx: FxQueue): void {
    let tx = NaN;
    let tz = 0;
    // sample a few agents rather than scanning the whole army
    for (let k = 0; k < 10; k++) {
      const a = this.rng.int(0, crowd.cap - 1);
      if (!crowd.isActive(a)) continue;
      if (Math.hypot(crowd.x[a]! - this.x[i]!, crowd.z[a]! - this.z[i]!) > TURRET_RANGE) continue;
      tx = crowd.x[a]!;
      tz = crowd.z[a]!;
      break;
    }
    if (tx !== tx) {
      if (this.z[i]! - cannonZ > TURRET_RANGE) return;
      tx = cannonX;
      tz = cannonZ;
    }
    for (let b = 0; b < MAX_BOLTS; b++) {
      if (this.boltLive[b]) continue;
      this.boltLive[b] = 1;
      this.boltSX[b] = this.boltX[b] = this.x[i]!;
      this.boltSZ[b] = this.boltZ[b] = this.z[i]!;
      this.boltTX[b] = tx;
      this.boltTZ[b] = tz;
      this.boltT[b] = 0;
      this.boltDmg[b] = this.dps[i]!;
      fx.push(FX.TurretShot, this.x[i]!, this.z[i]!);
      return;
    }
  }

  private updateBolts(dt: number, cannonX: number, cannonZ: number, crowd: CrowdSystem, fx: FxQueue): void {
    for (let b = 0; b < MAX_BOLTS; b++) {
      if (!this.boltLive[b]) continue;
      const dist = Math.hypot(this.boltTX[b]! - this.boltSX[b]!, this.boltTZ[b]! - this.boltSZ[b]!);
      this.boltT[b] += (dt * 16) / Math.max(1, dist);
      const t = Math.min(1, this.boltT[b]!);
      this.boltX[b] = this.boltSX[b]! + (this.boltTX[b]! - this.boltSX[b]!) * t;
      this.boltZ[b] = this.boltSZ[b]! + (this.boltTZ[b]! - this.boltSZ[b]!) * t;
      if (t < 1) continue;
      this.boltLive[b] = 0;
      const bx = this.boltX[b]!;
      const bz = this.boltZ[b]!;
      fx.push(FX.Impact, bx, bz);
      for (let a = 0; a < crowd.cap; a++) {
        if (!crowd.isActive(a)) continue;
        const dx = crowd.x[a]! - bx;
        const dz = crowd.z[a]! - bz;
        if (dx * dx + dz * dz < 1.2) crowd.damage(a, this.boltDmg[b]!, fx);
      }
      if (Math.abs(cannonX - bx) < 1.2 && Math.abs(cannonZ - bz) < 1.2) this.cannonDamage += this.boltDmg[b]! * 0.25;
    }
  }
}
