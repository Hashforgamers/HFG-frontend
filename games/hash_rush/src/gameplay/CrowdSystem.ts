import { Rng } from '../core/Rng';
import { FX, FxQueue, LEASH, MAX_AGENTS, SPAWN_BUDGET, TRACK_HALF, UNIT_CAP, UNIT_SPEED, clamp } from './constants';

export const AgentState = { Dead: 0, Run: 1, Fight: 2, Fall: 3, Die: 4, Cheer: 5 } as const;

/** A strip the army has to squeeze through (a narrow bridge). */
export interface Lane {
  z0: number;
  z1: number;
  x0: number;
  x1: number;
}

/**
 * The blue army.
 *
 * Logical vs rendered units: the game counts *units* (`count`), but simulates
 * and draws *agents*. An agent has a `strength` — how many units it stands
 * for. Normally that is 1. When the agent budget is spent, extra units are
 * added to existing agents' strength instead, so `count` (what the HUD shows,
 * what combat uses) is always exact while the instance count stays bounded.
 */
export class CrowdSystem {
  readonly cap: number;
  readonly x: Float32Array;
  readonly z: Float32Array;
  /** z at the start of the tick, for plane-crossing tests (gates, lasers). */
  readonly pz: Float32Array;
  readonly str: Int32Array;
  readonly hp: Float32Array;
  readonly state: Uint8Array;
  /** Seconds spent in the current state. */
  readonly t: Float32Array;
  readonly speed: Float32Array;
  readonly seedX: Float32Array;
  readonly seedZ: Float32Array;
  readonly phase: Float32Array;
  /** Steering target set by combat; NaN = none. */
  readonly tx: Float32Array;
  readonly tz: Float32Array;

  /** Logical units alive. */
  count = 0;
  /** Agents alive (Run or Fight). */
  alive = 0;
  unitHp = 10;
  unitCap = UNIT_CAP;
  /** Units lost so far (all causes). */
  lost = 0;

  private readonly free: Int32Array;
  private nFree: number;
  private cursor = 0;

  constructor(private readonly rng: Rng, cap = MAX_AGENTS) {
    this.cap = cap;
    this.x = new Float32Array(cap);
    this.z = new Float32Array(cap);
    this.pz = new Float32Array(cap);
    this.str = new Int32Array(cap);
    this.hp = new Float32Array(cap);
    this.state = new Uint8Array(cap);
    this.t = new Float32Array(cap);
    this.speed = new Float32Array(cap);
    this.seedX = new Float32Array(cap);
    this.seedZ = new Float32Array(cap);
    this.phase = new Float32Array(cap);
    this.tx = new Float32Array(cap).fill(NaN);
    this.tz = new Float32Array(cap);
    this.free = new Int32Array(cap);
    for (let i = 0; i < cap; i++) this.free[i] = cap - 1 - i;
    this.nFree = cap;
  }

  isActive(i: number): boolean {
    const s = this.state[i];
    return s === AgentState.Run || s === AgentState.Fight;
  }

  private spawn(x: number, z: number, strength: number): number {
    if (this.nFree === 0) return -1;
    const i = this.free[--this.nFree]!;
    this.x[i] = clamp(x, -TRACK_HALF + 0.3, TRACK_HALF - 0.3);
    this.z[i] = z;
    this.pz[i] = z;
    this.str[i] = strength;
    this.hp[i] = strength * this.unitHp;
    this.state[i] = AgentState.Run;
    this.t[i] = 0;
    this.speed[i] = 0;
    this.seedX[i] = this.rng.range(-1, 1);
    this.seedZ[i] = this.rng.next();
    this.phase[i] = this.rng.range(0, Math.PI * 2);
    this.tx[i] = NaN;
    this.alive++;
    this.count += strength;
    return i;
  }

  private anyActive(): number {
    for (let k = 0; k < this.cap; k++) {
      this.cursor = (this.cursor + 1) % this.cap;
      if (this.isActive(this.cursor)) return this.cursor;
    }
    return -1;
  }

  /**
   * Add `amount` logical units near (x, z). Returns how many were actually
   * added: fewer than requested only when the population cap is hit.
   * Up to `maxNew` become new agents; the rest raise `into`'s strength.
   */
  add(x: number, z: number, amount: number, maxNew = SPAWN_BUDGET, into = -1): number {
    const n = Math.min(Math.floor(amount), this.unitCap - this.count);
    if (n <= 0) return 0;
    const slots = Math.min(n, maxNew, this.nFree);
    if (slots === 0) {
      const target = into >= 0 && this.isActive(into) ? into : this.anyActive();
      if (target < 0) return 0;
      this.str[target] += n;
      this.hp[target] += n * this.unitHp;
      this.count += n;
      return n;
    }
    const base = Math.floor(n / slots);
    const extra = n - base * slots;
    for (let k = 0; k < slots; k++) {
      const jx = slots > 1 ? this.rng.range(-0.9, 0.9) : 0;
      const jz = slots > 1 ? this.rng.range(0, 1.2) : 0;
      this.spawn(x + jx, z + jz, base + (k < extra ? 1 : 0));
    }
    return n;
  }

  /** Apply damage to an agent's shared hit-point pool. Returns units lost. */
  damage(i: number, dmg: number, fx: FxQueue): number {
    if (!this.isActive(i)) return 0;
    this.hp[i] -= dmg;
    if (this.hp[i]! <= 0) {
      const s = this.str[i]!;
      this.kill(i, AgentState.Die, fx);
      return s;
    }
    const left = Math.ceil(this.hp[i]! / this.unitHp);
    const lostUnits = this.str[i]! - left;
    if (lostUnits > 0) {
      this.str[i] = left;
      this.count -= lostUnits;
      this.lost += lostUnits;
      fx.push(FX.UnitDie, this.x[i]!, this.z[i]!, 0);
    }
    return lostUnits;
  }

  /** Take `n` units out of one agent (bad gates). Returns how many were removed. */
  removeUnits(i: number, n: number, fx: FxQueue): number {
    if (!this.isActive(i) || n <= 0) return 0;
    const s = this.str[i]!;
    if (n >= s) {
      this.kill(i, AgentState.Die, fx);
      return s;
    }
    this.str[i] = s - n;
    this.hp[i] = Math.min(this.hp[i]!, (s - n) * this.unitHp);
    this.count -= n;
    this.lost += n;
    return n;
  }

  /** Take `n` units from the army, starting with agent `first`. Returns how many were removed. */
  removeAny(first: number, n: number, fx: FxQueue): number {
    let left = n - this.removeUnits(first, n, fx);
    while (left > 0) {
      const target = this.anyActive();
      if (target < 0) break;
      left -= this.removeUnits(target, left, fx);
    }
    return n - left;
  }

  /** Remove an agent outright (obstacles, pits, boss attacks). */
  kill(i: number, how: typeof AgentState.Die | typeof AgentState.Fall, fx: FxQueue): void {
    if (!this.isActive(i)) return;
    this.count -= this.str[i]!;
    this.lost += this.str[i]!;
    this.alive--;
    this.state[i] = how;
    this.t[i] = 0;
    this.tx[i] = NaN;
    fx.push(how === AgentState.Fall ? FX.UnitFall : FX.UnitDie, this.x[i]!, this.z[i]!, 1);
  }

  cheer(): void {
    for (let i = 0; i < this.cap; i++) {
      if (this.isActive(i)) {
        this.state[i] = AgentState.Cheer;
        this.t[i] = 0;
      }
    }
  }

  /** Formation half-width for the current army size. */
  spread(): number {
    return clamp(0.8 + Math.sqrt(this.alive) * 0.2, 0.8, TRACK_HALF - 0.6);
  }

  update(dt: number, cannonX: number, cannonZ: number, frontLimit: number, lanes: readonly Lane[]): void {
    const spread = this.spread();
    const depth = Math.min(12, 1.5 + Math.sqrt(this.alive) * 0.45);
    const centre = clamp(cannonX, -(TRACK_HALF - 0.4 - spread), TRACK_HALF - 0.4 - spread);
    const front = Math.min(cannonZ + LEASH, frontLimit);
    for (let i = 0; i < this.cap; i++) {
      const s = this.state[i]!;
      if (s === AgentState.Dead) continue;
      this.t[i] += dt;
      this.pz[i] = this.z[i]!;
      if (s === AgentState.Fall || s === AgentState.Die) {
        if (this.t[i]! > 0.7) {
          this.state[i] = AgentState.Dead;
          this.free[this.nFree++] = i;
        }
        continue;
      }
      if (s !== AgentState.Run) {
        this.speed[i] = 0;
        continue;
      }
      let x = this.x[i]!;
      let z = this.z[i]!;
      const tx = this.tx[i]!;
      if (tx === tx) {
        // charge the target picked by combat
        const dx = tx - x;
        const dz = this.tz[i]! - z;
        const d = Math.hypot(dx, dz) || 1;
        const step = Math.min(d, UNIT_SPEED * dt);
        x += (dx / d) * step;
        z += (dz / d) * step;
        this.speed[i] = UNIT_SPEED;
      } else {
        let fxTarget = centre + this.seedX[i]! * spread;
        for (let l = 0; l < lanes.length; l++) {
          const lane = lanes[l]!;
          // the army files across a bridge only if the cannon is lined up with it
          if (z > lane.z0 - 8 && z < lane.z1 && cannonX >= lane.x0 && cannonX <= lane.x1) {
            fxTarget = clamp(fxTarget, lane.x0 + 0.4, lane.x1 - 0.4);
          }
        }
        x += clamp((fxTarget - x) * 3, -5, 5) * dt;
        const limit = front - this.seedZ[i]! * depth;
        const step = Math.min(Math.max(0, limit - z), UNIT_SPEED * dt);
        z += step;
        this.speed[i] = step / dt;
      }
      this.x[i] = clamp(x, -TRACK_HALF + 0.3, TRACK_HALF - 0.3);
      this.z[i] = z;
    }
  }
}

/** Visual scale of an agent that stands for `strength` units. */
export function agentScale(strength: number): number {
  return strength <= 1 ? 1 : Math.min(2.6, 1 + 0.28 * Math.log2(strength));
}
