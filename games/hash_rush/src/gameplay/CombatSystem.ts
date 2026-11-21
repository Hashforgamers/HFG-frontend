import { BossSystem } from './BossSystem';
import { AgentState, CrowdSystem, agentScale } from './CrowdSystem';
import { ENEMY_STATS, EnemySystem } from './EnemySystem';
import { SpatialGrid } from './SpatialGrid';
import { FX, FxQueue } from './constants';

const SEEK_RANGE = 8;
const BOSS_SEEK = 22;
/** Agents that can be in melee with the boss at once. Keeps boss fights from ending in a blink. */
export const BOSS_CONTACT_CAP = 36;

/**
 * Damage an enemy takes from an agent in one tick.
 * `unitDamage` is damage per second per logical unit.
 */
export function agentDamage(strength: number, unitDamage: number, dt: number): number {
  return strength * unitDamage * dt;
}

/**
 * Damage an agent takes from the enemy it is fighting. An enemy mobbed by
 * many agents spreads its attacks: each takes dps/√attackers.
 */
export function enemyDamage(dps: number, attackers: number, dt: number): number {
  return (dps * dt) / Math.sqrt(Math.max(1, attackers));
}

/**
 * Melee resolution. Each blue agent finds the nearest enemy through the
 * spatial grid: in contact they trade damage, otherwise the agent is given a
 * steering target. Damage is aggregate — an agent of strength s hits s times
 * as hard and has s times the hit points.
 */
export function resolveCombat(
  dt: number, unitDamage: number,
  crowd: CrowdSystem, enemies: EnemySystem, grid: SpatialGrid, boss: BossSystem, fx: FxQueue,
): void {
  const bossR = boss.stats.radius;
  for (let i = 0; i < crowd.cap; i++) {
    const s = crowd.state[i]!;
    if (s !== AgentState.Run && s !== AgentState.Fight) continue;
    const x = crowd.x[i]!;
    const z = crowd.z[i]!;
    const str = crowd.str[i]!;
    const reach = 0.3 * agentScale(str) + 0.25;
    crowd.state[i] = AgentState.Run;
    crowd.tx[i] = NaN;

    const e = grid.nearest(x, z, SEEK_RANGE);
    if (e >= 0) {
      const d = Math.hypot(enemies.x[e]! - x, enemies.z[e]! - z);
      if (d <= reach + ENEMY_STATS[enemies.kind[e]!]!.radius) {
        crowd.state[i] = AgentState.Fight;
        enemies.attackers[e]++;
        const wasHurt = enemies.flash[e]! > 0.05;
        const killed = enemies.hit(e, agentDamage(str, unitDamage, dt), fx);
        if (!killed && !wasHurt) fx.push(FX.EnemyHit, enemies.x[e]!, enemies.z[e]!);
        if (enemies.kind[e] !== 3) crowd.damage(i, enemyDamage(enemies.dps[e]!, enemies.attackersPrev[e]!, dt), fx);
      } else {
        crowd.tx[i] = enemies.x[e]!;
        crowd.tz[i] = enemies.z[e]!;
      }
      continue;
    }
    if (!boss.targetable) continue;
    const d = Math.hypot(boss.x - x, boss.z - z);
    if (d <= reach + bossR) {
      // only so many units fit around a boss; the rest of the army waits its turn
      if (boss.attackers >= BOSS_CONTACT_CAP) continue;
      crowd.state[i] = AgentState.Fight;
      boss.attackers++;
      boss.hit(agentDamage(str, unitDamage, dt), fx);
      crowd.damage(i, enemyDamage(boss.stats.meleeDps * boss.tier, boss.attackersPrev, dt), fx);
    } else if (d < BOSS_SEEK) {
      crowd.tx[i] = boss.x;
      crowd.tz[i] = boss.z;
    }
  }
}
