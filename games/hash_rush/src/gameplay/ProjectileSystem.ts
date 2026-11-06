import { CrowdSystem } from './CrowdSystem';
import { ENEMY_STATS, EnemySystem } from './EnemySystem';
import { GateSystem } from './GateSystem';
import { ObstacleSystem } from './ObstacleSystem';
import { SpatialGrid } from './SpatialGrid';
import { FX, FxQueue, POD_RANGE, POD_SPEED } from './constants';

/** Anything a pod can hit besides the red army. */
export interface PodTarget {
  /** Returns true if the pod at (x, z) hit and was consumed. */
  podHit(x: number, z: number, dmg: number, fx: FxQueue): boolean;
}

/**
 * Pods are what the cannon fires. A pod is NOT a unit: it flies POD_RANGE
 * metres and then lands, deploying exactly one unit. If it strikes an enemy,
 * barrel or boss first it deals `podDamage` and deploys nothing. A pod never
 * flies through a gate — it touches down just in front of it, and the unit it
 * deploys then walks through.
 */
export class ProjectileSystem {
  readonly cap = 48;
  readonly x = new Float32Array(this.cap);
  readonly z = new Float32Array(this.cap);
  readonly startZ = new Float32Array(this.cap);
  readonly live = new Uint8Array(this.cap);
  fired = 0;
  deployed = 0;
  hits = 0;

  fire(x: number, z: number): void {
    let slot = -1;
    let oldest = 0;
    for (let i = 0; i < this.cap; i++) {
      if (!this.live[i]) {
        slot = i;
        break;
      }
      // pool full (cannot happen at sane fire rates): recycle the pod that has flown furthest
      if (this.z[i]! - this.startZ[i]! > this.z[oldest]! - this.startZ[oldest]!) oldest = i;
    }
    if (slot < 0) slot = oldest;
    this.live[slot] = 1;
    this.x[slot] = x;
    this.z[slot] = this.startZ[slot] = z;
    this.fired++;
  }

  update(
    dt: number, podDamage: number, maxZ: number,
    crowd: CrowdSystem, enemies: EnemySystem, grid: SpatialGrid, gates: GateSystem,
    obstacles: ObstacleSystem, boss: PodTarget, fx: FxQueue,
  ): void {
    for (let i = 0; i < this.cap; i++) {
      if (!this.live[i]) continue;
      const x = this.x[i]!;
      const prev = this.z[i]!;
      let z = prev + POD_SPEED * dt;
      let land = false;

      const e = grid.nearest(x, z, 1.7);
      if (e >= 0) {
        const r = ENEMY_STATS[enemies.kind[e]!]!.radius + 0.35;
        if (Math.hypot(enemies.x[e]! - x, enemies.z[e]! - z) < r) {
          enemies.hit(e, podDamage, fx);
          fx.push(FX.PodHit, x, z);
          this.live[i] = 0;
          this.hits++;
          continue;
        }
      }
      if (obstacles.hitBarrel(x, z, 0.7, crowd, enemies, fx) || boss.podHit(x, z, podDamage, fx)) {
        fx.push(FX.PodHit, x, z);
        this.live[i] = 0;
        this.hits++;
        continue;
      }
      for (let g = 0; g < gates.gates.length; g++) {
        const gate = gates.gates[g]!;
        if (GateSystem.crossed(gate, x, prev, z)) {
          z = gate.def.z - 0.4;
          land = true;
          break;
        }
      }
      if (z - this.startZ[i]! >= POD_RANGE || z >= maxZ) land = true;
      this.z[i] = z;
      if (land) {
        this.live[i] = 0;
        this.deployed += crowd.add(x, Math.min(z, maxZ), 1, 1);
        fx.push(FX.PodLand, x, z);
      }
    }
  }
}
