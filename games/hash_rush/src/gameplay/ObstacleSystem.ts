import type { ObstacleDef } from '../levels/LevelConfig';
import { AgentState, CrowdSystem, type Lane } from './CrowdSystem';
import { EnemySystem } from './EnemySystem';
import { FX, FxQueue } from './constants';

export const BARREL_RADIUS = 3.4;
const BARREL_UNIT_RADIUS = 2.0;

export interface ObstacleRuntime {
  def: ObstacleDef;
  /** Current centre across the track (moving wall). */
  x: number;
  /** Blade rotation, radians. */
  angle: number;
  /** Crusher height: 1 raised, 0 slammed. */
  y: number;
  /** 0 safe, 1 warning (about to become lethal), 2 lethal. */
  danger: 0 | 1 | 2;
  /** Falling platform: 0 intact, 1 shaking, 2 gone. Barrel: 0 intact, 2 exploded. */
  stage: 0 | 1 | 2;
  t: number;
}

/** Traps. Every one has a collision rule, a damage rule and a warning state the view can show. */
export class ObstacleSystem {
  readonly list: ObstacleRuntime[];
  /** Bridges, exposed so the army and enemies can file across. */
  readonly lanes: Lane[] = [];
  time = 0;
  unitsKilled = 0;

  constructor(defs: readonly ObstacleDef[], private readonly barrelDamage = 90) {
    this.list = defs.map((def) => ({ def, x: 0, angle: 0, y: 1, danger: 0, stage: 0, t: 0 }));
    for (const def of defs) if (def.kind === 'bridge') this.lanes.push(def);
  }

  /** Detonate the barrel nearest to (x, z) within r. Returns true if one went off. */
  hitBarrel(x: number, z: number, r: number, crowd: CrowdSystem, enemies: EnemySystem, fx: FxQueue): boolean {
    for (const o of this.list) {
      if (o.def.kind !== 'barrel' || o.stage !== 0) continue;
      if (Math.hypot(o.def.x - x, o.def.z - z) > r) continue;
      this.explode(o, crowd, enemies, fx);
      return true;
    }
    return false;
  }

  private explode(o: ObstacleRuntime, crowd: CrowdSystem, enemies: EnemySystem, fx: FxQueue): void {
    if (o.def.kind !== 'barrel' || o.stage !== 0) return;
    o.stage = 2;
    const bx = o.def.x;
    const bz = o.def.z;
    fx.push(FX.Explosion, bx, bz, BARREL_RADIUS);
    for (let i = 0; i < enemies.cap; i++) {
      if (!enemies.isAlive(i)) continue;
      if (Math.hypot(enemies.x[i]! - bx, enemies.z[i]! - bz) < BARREL_RADIUS) enemies.hit(i, this.barrelDamage, fx);
    }
    for (let i = 0; i < crowd.cap; i++) {
      if (!crowd.isActive(i)) continue;
      if (Math.hypot(crowd.x[i]! - bx, crowd.z[i]! - bz) < BARREL_UNIT_RADIUS) this.kill(crowd, i, AgentState.Die, fx);
    }
    // chain reaction
    for (const other of this.list) {
      if (other.def.kind === 'barrel' && other.stage === 0 && Math.hypot(other.def.x - bx, other.def.z - bz) < BARREL_RADIUS) {
        this.explode(other, crowd, enemies, fx);
      }
    }
  }

  private kill(crowd: CrowdSystem, i: number, how: typeof AgentState.Die | typeof AgentState.Fall, fx: FxQueue): void {
    this.unitsKilled += crowd.str[i]!;
    crowd.kill(i, how, fx);
  }

  update(dt: number, crowd: CrowdSystem, enemies: EnemySystem, fx: FxQueue, zMin: number, zMax: number): void {
    this.time += dt;
    for (const o of this.list) {
      const def = o.def;
      o.t += dt;
      const near = (z0: number, z1: number) => z1 > zMin - 4 && z0 < zMax + 4;
      switch (def.kind) {
        case 'movingWall': {
          o.x = Math.sin(this.time * def.speed + (def.phase ?? 0)) * def.amp;
          o.danger = 2;
          if (!near(def.z, def.z)) break;
          const half = def.width / 2;
          for (let i = 0; i < crowd.cap; i++) {
            if (!crowd.isActive(i)) continue;
            if (Math.abs(crowd.x[i]! - o.x) > half + 0.2) continue;
            if (crowd.pz[i]! <= def.z + 0.5 && crowd.z[i]! >= def.z - 0.5) this.kill(crowd, i, AgentState.Die, fx);
          }
          break;
        }
        case 'blade': {
          o.angle += def.speed * dt;
          o.danger = 2;
          if (!near(def.z - def.radius, def.z + def.radius)) break;
          for (let i = 0; i < crowd.cap; i++) {
            if (!crowd.isActive(i)) continue;
            const dx = crowd.x[i]! - def.x;
            const dz = crowd.z[i]! - def.z;
            const d = Math.hypot(dx, dz);
            if (d > def.radius + 0.25) continue;
            // two opposed arms: compare the agent's bearing with the blade line
            let diff = (Math.atan2(dz, dx) - o.angle) % Math.PI;
            if (diff > Math.PI / 2) diff -= Math.PI;
            if (diff < -Math.PI / 2) diff += Math.PI;
            if (d < 0.5 || Math.abs(diff) * d < 0.45) this.kill(crowd, i, AgentState.Die, fx);
          }
          break;
        }
        case 'crusher': {
          const p = ((this.time + (def.phase ?? 0)) % def.period) / def.period;
          const was = o.y;
          if (p < 0.5) (o.y = 1), (o.danger = 0);
          else if (p < 0.74) (o.y = 1), (o.danger = 1);
          else if (p < 0.79) (o.y = 1 - (p - 0.74) / 0.05), (o.danger = 2);
          else if (p < 0.9) (o.y = 0), (o.danger = 2);
          else (o.y = (p - 0.9) / 0.1), (o.danger = 0);
          if (!near(def.z - def.depth, def.z + def.depth)) break;
          if (was > 0 && o.y === 0) fx.push(FX.Impact, def.x, def.z, 1);
          if (o.danger !== 2) break;
          for (let i = 0; i < crowd.cap; i++) {
            if (!crowd.isActive(i)) continue;
            if (Math.abs(crowd.x[i]! - def.x) < def.width / 2 && Math.abs(crowd.z[i]! - def.z) < def.depth / 2) {
              this.kill(crowd, i, AgentState.Die, fx);
            }
          }
          break;
        }
        case 'laser': {
          const p = ((this.time + (def.phase ?? 0)) % def.period) / def.period;
          o.danger = p < 0.4 ? 0 : p < 0.58 ? 1 : 2;
          if (o.danger !== 2 || !near(def.z, def.z)) break;
          for (let i = 0; i < crowd.cap; i++) {
            if (!crowd.isActive(i)) continue;
            const x = crowd.x[i]!;
            if (x < def.x0 || x > def.x1) continue;
            if (crowd.pz[i]! <= def.z + 0.3 && crowd.z[i]! >= def.z - 0.3) this.kill(crowd, i, AgentState.Die, fx);
          }
          break;
        }
        case 'bridge': {
          if (!near(def.z0, def.z1)) break;
          for (let i = 0; i < crowd.cap; i++) {
            if (!crowd.isActive(i)) continue;
            const z = crowd.z[i]!;
            if (z <= def.z0 || z >= def.z1) continue;
            if (crowd.x[i]! < def.x0 || crowd.x[i]! > def.x1) this.kill(crowd, i, AgentState.Fall, fx);
          }
          break;
        }
        case 'fallingPlatform': {
          if (!near(def.z0, def.z1)) break;
          if (o.stage === 1 && o.t > 1.3) {
            o.stage = 2;
            fx.push(FX.Collapse, (def.x0 + def.x1) / 2, (def.z0 + def.z1) / 2);
          }
          o.danger = o.stage === 0 ? 0 : o.stage;
          for (let i = 0; i < crowd.cap; i++) {
            if (!crowd.isActive(i)) continue;
            const z = crowd.z[i]!;
            const x = crowd.x[i]!;
            if (z <= def.z0 || z >= def.z1 || x < def.x0 || x > def.x1) continue;
            if (o.stage === 0) {
              o.stage = 1;
              o.t = 0;
            } else if (o.stage === 2) {
              this.kill(crowd, i, AgentState.Fall, fx);
            }
          }
          break;
        }
        case 'barrel': {
          if (o.stage !== 0 || !near(def.z, def.z)) break;
          for (let i = 0; i < crowd.cap; i++) {
            if (!crowd.isActive(i)) continue;
            if (Math.abs(crowd.x[i]! - def.x) < 0.75 && Math.abs(crowd.z[i]! - def.z) < 0.75) {
              this.explode(o, crowd, enemies, fx);
              break;
            }
          }
          break;
        }
      }
    }
  }
}
