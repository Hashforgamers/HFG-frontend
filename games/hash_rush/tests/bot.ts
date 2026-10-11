import { Simulation, type SimInput } from '../src/gameplay/Simulation';
import { SIM_DT, TRACK_HALF } from '../src/gameplay/constants';
import type { LevelConfig } from '../src/levels/LevelConfig';
import type { PlayerStats } from '../src/gameplay/Upgrades';

export type BotSkill = 'good' | 'poor' | 'idle';

/**
 * A scripted player. 'good' picks the better gate, lines up with bridges,
 * avoids pits and dodges boss attacks; 'poor' picks the worse gate and never
 * dodges; 'idle' never moves. Used for win/loss tests and the balance report.
 */
export function botAim(sim: Simulation, skill: BotSkill): number {
  if (skill === 'idle') return 0;
  const cz = sim.cannon.z;
  const cx = sim.cannon.x;
  if (skill === 'good') {
    // dodge: step out of any telegraph that would hit the cannon
    for (const tg of sim.boss.telegraphs) {
      if (!tg.live || tg.cannonDmg <= 0) continue;
      if (Math.abs(cz - tg.z) > tg.hd + 0.6 || Math.abs(cx - tg.x) > tg.hw + 1.2) continue;
      const left = tg.x - tg.hw - 1.6;
      const right = tg.x + tg.hw + 1.6;
      const lim = TRACK_HALF - 0.9;
      if (left < -lim) return right;
      if (right > lim) return left;
      return Math.abs(cx - left) < Math.abs(cx - right) ? left : right;
    }
    for (const o of sim.obstacles.list) {
      const d = o.def;
      if (d.kind === 'bridge' && d.z1 > cz && d.z0 - cz < 34) return (d.x0 + d.x1) / 2;
      if (d.kind === 'fallingPlatform' && d.z1 > cz - 2 && d.z0 - cz < 32) return d.x0 > -1 ? d.x0 - 2.6 : d.x1 + 2.6;
    }
  }
  // next gate row ahead of the army front
  let rowZ = Infinity;
  for (const g of sim.gates.gates) if (g.def.z > cz + 2 && g.def.z < rowZ) rowZ = g.def.z;
  if (rowZ - cz > 40) return 0;
  let best = 0;
  let bestValue = skill === 'good' ? -Infinity : Infinity;
  const army = Math.max(1, sim.crowd.count);
  for (const g of sim.gates.gates) {
    if (g.def.z !== rowZ) continue;
    const op = g.def.op;
    const value = op.kind === 'mul' ? army * (op.value - 1) : op.kind === 'add' ? op.value : op.kind === 'sub' ? -op.value : -army * (1 - 1 / op.value);
    if (skill === 'good' ? value > bestValue : value < bestValue) {
      bestValue = value;
      best = g.x;
    }
  }
  return best;
}

export function playLevel(level: LevelConfig, stats: PlayerStats, skill: BotSkill, maxSeconds = 600): Simulation {
  const sim = new Simulation(level, stats);
  const input: SimInput = { aimX: 0, ability: false };
  const maxSteps = maxSeconds / SIM_DT;
  for (let i = 0; i < maxSteps && sim.status === 'playing'; i++) {
    input.aimX = botAim(sim, skill);
    input.ability = skill !== 'idle' && (sim.enemies.blockerZ < Infinity || sim.boss.targetable);
    sim.step(input);
  }
  return sim;
}
