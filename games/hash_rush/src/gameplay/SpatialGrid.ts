import { TRACK_HALF } from './constants';
import { EnemySystem } from './EnemySystem';

const CELL = 4;
const COLS = Math.ceil((TRACK_HALF * 2 + 2) / CELL);

/**
 * Uniform grid over the living enemies, rebuilt each tick (linked lists in
 * typed arrays, no allocation). Lets a few hundred blue agents each find the
 * nearest enemy without an O(n·m) scan.
 */
export class SpatialGrid {
  private head = new Int32Array(0);
  private readonly next: Int32Array;
  private rows = 0;
  private z0 = 0;

  constructor(private readonly enemies: EnemySystem) {
    this.next = new Int32Array(enemies.cap);
  }

  build(zMin: number, zMax: number): void {
    this.z0 = Math.floor(zMin / CELL);
    this.rows = Math.floor(zMax / CELL) - this.z0 + 1;
    const cells = this.rows * COLS;
    if (this.head.length < cells) this.head = new Int32Array(cells);
    this.head.fill(-1, 0, cells);
    const e = this.enemies;
    for (let i = 0; i < e.cap; i++) {
      if (!e.isAlive(i)) continue;
      const row = Math.floor(e.z[i]! / CELL) - this.z0;
      if (row < 0 || row >= this.rows) continue;
      const cell = row * COLS + this.col(e.x[i]!);
      this.next[i] = this.head[cell]!;
      this.head[cell] = i;
    }
  }

  private col(x: number): number {
    const c = Math.floor((x + TRACK_HALF + 1) / CELL);
    return c < 0 ? 0 : c >= COLS ? COLS - 1 : c;
  }

  /** Index of the living enemy nearest to (x, z) within `range`, or -1. */
  nearest(x: number, z: number, range: number): number {
    const e = this.enemies;
    const r0 = Math.max(0, Math.floor((z - range) / CELL) - this.z0);
    const r1 = Math.min(this.rows - 1, Math.floor((z + range) / CELL) - this.z0);
    const c0 = this.col(x - range);
    const c1 = this.col(x + range);
    let best = -1;
    let bestD = range * range;
    for (let r = r0; r <= r1; r++) {
      for (let c = c0; c <= c1; c++) {
        for (let i = this.head[r * COLS + c]!; i >= 0; i = this.next[i]!) {
          const dx = e.x[i]! - x;
          const dz = e.z[i]! - z;
          const d = dx * dx + dz * dz;
          if (d < bestD) {
            bestD = d;
            best = i;
          }
        }
      }
    }
    return best;
  }
}
