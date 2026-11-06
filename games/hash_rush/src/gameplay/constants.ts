/** Half-width of the playable track, metres. */
export const TRACK_HALF = 5;
export const SIM_DT = 1 / 60;

/**
 * Simulated (and rendered) blue agents. One agent normally stands for one
 * unit; once this budget is spent, new units are folded into existing agents
 * as extra `strength` — see docs/GAMEPLAY_RULES.md.
 */
export const MAX_AGENTS = 600;
export const MAX_ENEMIES = 320;
/** Hard population cap on logical blue units. Gate output beyond it is dropped and reported. */
export const UNIT_CAP = 5000;
/** At most this many new agents appear per gate activation; the rest become strength. */
export const SPAWN_BUDGET = 24;

/** How far ahead of the cannon the army may run before it holds formation. */
export const LEASH = 17;
export const UNIT_SPEED = 9;
export const CANNON_SPEED = 3.4;
export const CANNON_HP = 100;
export const POD_SPEED = 24;
export const POD_RANGE = 6.5;
/** The cannon parks this far short of the boss. */
export const BOSS_STANDOFF = 17;

export const FX = {
  Muzzle: 0,
  PodLand: 1,
  PodHit: 2,
  UnitDie: 3,
  UnitFall: 4,
  EnemyHit: 5,
  EnemyDie: 6,
  GateAdd: 7,
  GateMul: 8,
  GateCapped: 9,
  Explosion: 10,
  BossHit: 11,
  BossAttack: 12,
  BossDie: 13,
  CannonHit: 14,
  Impact: 15,
  BossIntro: 16,
  Collapse: 17,
  TurretShot: 18,
  Ability: 19,
  BossShield: 20,
  Victory: 21,
  Summon: 22,
  GateLoss: 23,
} as const;
export type FxType = (typeof FX)[keyof typeof FX];

/**
 * Sim -> presentation event queue. Plain typed arrays, reused every tick, so
 * the simulation never allocates while reporting what happened.
 */
export class FxQueue {
  static readonly CAP = 256;
  readonly type = new Uint8Array(FxQueue.CAP);
  readonly x = new Float32Array(FxQueue.CAP);
  readonly z = new Float32Array(FxQueue.CAP);
  readonly a = new Float32Array(FxQueue.CAP);
  n = 0;
  push(type: FxType, x: number, z: number, a = 0): void {
    if (this.n >= FxQueue.CAP) return;
    const i = this.n++;
    this.type[i] = type;
    this.x[i] = x;
    this.z[i] = z;
    this.a[i] = a;
  }
  clear(): void {
    this.n = 0;
  }
}

export function clamp(v: number, lo: number, hi: number): number {
  return v < lo ? lo : v > hi ? hi : v;
}
