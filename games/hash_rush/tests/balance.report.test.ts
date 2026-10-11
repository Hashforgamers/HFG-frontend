import { describe, expect, it } from 'vitest';
import { computeStats, zeroUpgrades, type UpgradeLevels } from '../src/gameplay/Upgrades';
import { LEVEL_COUNT, getLevel } from '../src/levels/LevelManager';
import { playLevel } from './bot';

/** Upgrade levels a player plausibly has on reaching level n (about one purchase per level). */
function expectedUpgrades(n: number): UpgradeLevels {
  const u = zeroUpgrades();
  const each = Math.min(12, Math.floor((n - 1) / 3));
  u.fireRate = u.unitDamage = u.unitHealth = u.cannonPower = each;
  u.startArmy = Math.min(15, Math.floor((n - 1) / 2));
  u.abilityCooldown = Math.min(10, Math.floor((n - 1) / 4));
  return u;
}

describe('balance report (headless bots over all levels)', () => {
  it('prints the progression curve', () => {
    const rows: string[] = [];
    let goodWins = 0;
    let firstFive = 0;
    for (let n = 1; n <= LEVEL_COUNT; n++) {
      const level = getLevel(n);
      const stats = computeStats(expectedUpgrades(n));
      const good = playLevel(level, stats, 'good');
      const poor = playLevel(level, stats, 'poor');
      const fresh = playLevel(level, computeStats(zeroUpgrades()), 'good');
      if (good.status === 'won') goodWins++;
      if (good.status === 'won' && n <= 5) firstFive++;
      expect(good.status, `level ${n} must terminate`).not.toBe('playing');
      const g = good.summary();
      rows.push(
        `L${String(n).padStart(2)} ${level.world.padEnd(8)} ${level.boss.kind.padEnd(7)} ` +
          `good:${g.status.padEnd(7)} t=${g.time.toFixed(0).padStart(3)}s peak=${String(g.peakArmy).padStart(4)} ` +
          `hp=${g.cannonHp.toFixed(0).padStart(3)} score=${String(g.score).padStart(5)} | ` +
          `poor:${poor.status.padEnd(7)} hp=${poor.cannon.hp.toFixed(0).padStart(3)} peak=${String(poor.peakArmy).padStart(4)} | ` +
          `noUpg:${fresh.status}`,
      );
    }
    console.log('\n' + rows.join('\n'));
    console.log(`good bot wins ${goodWins}/${LEVEL_COUNT}`);
    // the bot never dodges walls, blades, crushers or lasers, so it is a floor, not a ceiling
    expect(firstFive).toBe(5);
    expect(goodWins).toBeGreaterThanOrEqual(Math.floor(LEVEL_COUNT * 0.85));
  });
});
