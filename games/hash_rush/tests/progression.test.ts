import { describe, expect, it } from 'vitest';
import { SAVE_KEY, applyRun, careerScore, grantUpgrade, defaultSave, loadSave, storeSave } from '../src/core/GameState';
import { GameLoop } from '../src/core/GameLoop';
import type { RunSummary } from '../src/gameplay/Simulation';
import { MAX_LEVEL_SCORE } from '../src/gameplay/Simulation';
import { MockAdapter } from '../src/integration/MockAdapter';
import { WORLD_ORDER } from '../src/levels/LevelConfig';
import { difficulty } from '../src/levels/LevelGenerator';
import { LEVEL_COUNT, getLevel, validateLevel } from '../src/levels/LevelManager';
import { ObjectPool } from '../src/optimization/ObjectPool';
import { PRESETS, QualityManager } from '../src/optimization/QualityManager';

class MemoryStorage {
  data = new Map<string, string>();
  fail = false;
  getItem(k: string) {
    return this.data.get(k) ?? null;
  }
  setItem(k: string, v: string) {
    if (this.fail) throw new Error('QuotaExceededError');
    this.data.set(k, v);
  }
}

const run = (over: Partial<RunSummary> = {}): RunSummary => ({
  levelId: 1, status: 'won', score: 3000, time: 50, enemiesKilled: 30, unitsLost: 10, peakArmy: 200, armyLeft: 150,
  gateActivations: 40, cannonHp: 100, stars: 3, ...over,
});

describe('level progression', () => {
  it('has 30 valid levels', () => {
    expect(LEVEL_COUNT).toBe(30);
    for (let n = 1; n <= LEVEL_COUNT; n++) {
      const level = getLevel(n);
      expect(level.id).toBe(n);
      expect(validateLevel(level), `level ${n}`).toEqual([]);
    }
  });

  it('the first five levels visit all five worlds and all three bosses', () => {
    const first = [1, 2, 3, 4, 5].map(getLevel);
    expect(new Set(first.map((l) => l.world)).size).toBe(5);
    expect(new Set(first.map((l) => l.boss.kind)).size).toBe(3);
    expect(first.map((l) => l.world)).toEqual([...WORLD_ORDER]);
  });

  it('every obstacle type and gate value appears somewhere', () => {
    const kinds = new Set<string>();
    const gates = new Set<string>();
    let moving = 0;
    for (let n = 1; n <= LEVEL_COUNT; n++) {
      const level = getLevel(n);
      level.obstacles.forEach((o) => kinds.add(o.kind));
      level.gates.forEach((g) => (gates.add(g.op.kind + g.op.value), g.moveAmp && moving++));
      level.waves.forEach((w) => kinds.add(w.kind));
    }
    for (const k of ['movingWall', 'blade', 'crusher', 'laser', 'bridge', 'fallingPlatform', 'barrel', 'turret', 'grunt', 'brute', 'giant']) {
      expect(kinds.has(k), k).toBe(true);
    }
    for (const g of ['add5', 'add10', 'add25', 'mul2', 'mul3', 'mul5', 'mul10', 'mul100', 'sub10', 'sub25', 'div2']) expect(gates.has(g), g).toBe(true);
    expect(moving).toBeGreaterThan(3);
  });

  it('difficulty and rewards rise with the level number', () => {
    for (let n = 2; n <= LEVEL_COUNT; n++) {
      expect(difficulty(n).enemyHpScale).toBeGreaterThan(difficulty(n - 1).enemyHpScale);
      expect(difficulty(n).credits).toBeGreaterThan(difficulty(n - 1).credits);
    }
    expect(getLevel(30).boss.tier).toBeGreaterThan(getLevel(1).boss.tier);
  });

  it('levels are generated identically every time', () => {
    expect(JSON.stringify(getLevel(17))).toBe(JSON.stringify(getLevel(17)));
  });

  it('out-of-range level numbers are clamped', () => {
    expect(getLevel(0).id).toBe(1);
    expect(getLevel(999).id).toBe(LEVEL_COUNT);
  });

  it('winning unlocks the next level; losing does not', () => {
    const save = defaultSave();
    expect(applyRun(save, getLevel(1), run({ status: 'lost', stars: 0 })).unlockedLevel).toBeNull();
    expect(save.unlocked).toBe(1);
    expect(save.best[1]).toBeUndefined();
    expect(applyRun(save, getLevel(1), run()).unlockedLevel).toBe(2);
    expect(save.unlocked).toBe(2);
    // replaying an old level never moves the frontier backwards or forwards
    applyRun(save, getLevel(1), run());
    expect(save.unlocked).toBe(2);
  });

  it('the last level does not unlock a level 31', () => {
    const save = defaultSave();
    save.unlocked = LEVEL_COUNT;
    applyRun(save, getLevel(LEVEL_COUNT), run({ levelId: LEVEL_COUNT }));
    expect(save.unlocked).toBe(LEVEL_COUNT);
  });

  it('keeps the best score and stars per level, and sums them into the career score', () => {
    const save = defaultSave();
    expect(applyRun(save, getLevel(1), run({ score: 3000, stars: 2 })).newBest).toBe(true);
    expect(applyRun(save, getLevel(1), run({ score: 2000, stars: 3 })).newBest).toBe(false);
    applyRun(save, getLevel(2), run({ levelId: 2, score: 4500 }));
    expect(save.best[1]).toEqual({ score: 3000, stars: 3 });
    expect(careerScore(save)).toBe(7500);
    expect(careerScore(save)).toBeLessThanOrEqual(LEVEL_COUNT * MAX_LEVEL_SCORE);
  });

  it('a granted upgrade goes up one level and stops at the cap', () => {
    const save = defaultSave();
    expect(grantUpgrade(save, 'fireRate')).toBe(true);
    expect(save.upgrades.fireRate).toBe(1);
    while (grantUpgrade(save, 'abilityCooldown'));
    expect(save.upgrades.abilityCooldown).toBe(10);
  });
});

describe('save / load', () => {
  it('round-trips', () => {
    const storage = new MemoryStorage();
    const save = defaultSave();
    save.upgrades.unitDamage = 3;
    save.settings.music = false;
    save.settings.quality = 'low';
    applyRun(save, getLevel(1), run());
    save.pending.push({ runId: 'r1', score: 99, level: 1 });
    expect(storeSave(storage, save)).toBe(true);
    expect(loadSave(storage)).toEqual(save);
  });

  it('starts fresh from missing or corrupt data', () => {
    const storage = new MemoryStorage();
    expect(loadSave(storage)).toEqual(defaultSave());
    expect(loadSave(null)).toEqual(defaultSave());
    for (const junk of ['{not json', '42', 'null', '[]', '"x"']) {
      storage.data.set(SAVE_KEY, junk);
      expect(loadSave(storage)).toEqual(defaultSave());
    }
  });

  it('sanitises tampered values', () => {
    const storage = new MemoryStorage();
    storage.data.set(SAVE_KEY, JSON.stringify({
      unlocked: 9999, upgrades: { fireRate: 500, unitDamage: 'lots', bogus: 3 },
      best: { 1: { score: 'x', stars: 9 }, 77: { score: 5, stars: 1 }, abc: {} }, settings: { quality: 'ultra', sfx: false }, pending: 'nope',
    }));
    const save = loadSave(storage);
    expect(save.unlocked).toBe(LEVEL_COUNT);
    expect(save.upgrades.fireRate).toBe(15);
    expect(save.upgrades.unitDamage).toBe(0);
    expect(save.best).toEqual({ 1: { score: 0, stars: 3 } });
    expect(save.settings).toEqual({ music: true, sfx: false, haptics: true, quality: 'auto' });
    expect(save.pending).toEqual([]);
  });

  it('a storage failure is reported, not thrown', () => {
    const storage = new MemoryStorage();
    storage.fail = true;
    expect(storeSave(storage, defaultSave())).toBe(false);
    expect(storeSave(null, defaultSave())).toBe(false);
  });

  it('a reload mid-run loses only that run: nothing is written until a run finishes', () => {
    const storage = new MemoryStorage();
    const save = defaultSave();
    applyRun(save, getLevel(1), run());
    storeSave(storage, save);
    // ...level 2 is in progress, the page reloads...
    const reloaded = loadSave(storage);
    expect(reloaded.unlocked).toBe(2);
    expect(reloaded.best[2]).toBeUndefined();
  });
});

describe('integration adapter (mock)', () => {
  const submission = { runId: 'a', score: 5000, level: 1, levelScore: 5000, stars: 3, durationMs: 50000, proof: { enemiesKilled: 1, peakArmy: 1, gateActivations: 1, unitsLost: 0 } };

  it('accepts a score once and rejects the duplicate', async () => {
    const adapter = new MockAdapter();
    expect((await adapter.submitScore(submission)).accepted).toBe(true);
    expect((await adapter.submitScore(submission)).accepted).toBe(false);
    expect((await adapter.submitScore({ ...submission, runId: 'b', score: NaN })).accepted).toBe(false);
    const board = await adapter.getLeaderboard(50);
    expect(board.find((e) => e.isPlayer)?.score).toBe(5000);
    expect(board.map((e) => e.rank)).toEqual(board.map((_, i) => i + 1));
  });

  it('a network failure rejects, so the game can queue the score', async () => {
    const adapter = new MockAdapter({ offline: true });
    await expect(adapter.submitScore(submission)).rejects.toThrow();
    await expect(adapter.getLeaderboard(10)).rejects.toThrow();
    adapter.options.offline = false;
    expect((await adapter.submitScore(submission)).accepted).toBe(true);
  });

  it('is a guest and never eligible for real rewards', async () => {
    const adapter = new MockAdapter();
    expect((await adapter.getPlayer()).isGuest).toBe(true);
    expect((await adapter.getRewardEligibility()).eligible).toBe(false);
  });

  it('analytics never throws and is bounded', () => {
    const adapter = new MockAdapter();
    for (let i = 0; i < 2000; i++) adapter.track('enemy_defeated', { count: i });
    expect(adapter.events.length).toBe(500);
  });
});

describe('optimisation helpers', () => {
  it('object pool never allocates past its size', () => {
    let made = 0;
    const pool = new ObjectPool(4, () => ({ id: made++ }));
    const a = pool.acquire();
    for (let i = 0; i < 20; i++) pool.acquire();
    expect(made).toBe(4);
    pool.release(a);
    expect(pool.acquire()).toBe(a);
    pool.releaseAll();
    let busy = 0;
    pool.forEachBusy(() => busy++);
    expect(busy).toBe(0);
  });

  it('quality drops resolution, then the preset, under sustained slow frames', () => {
    const changes: string[] = [];
    const q = new QualityManager('high', (p, changed) => changes.push(`${p.level}:${changed}`));
    for (let i = 0; i < QualityManager.WINDOW * 4; i++) q.sample(30);
    expect(q.scale).toBeCloseTo(QualityManager.MIN_SCALE);
    expect(q.level).toBe('high'); // a fixed setting never changes preset
    q.set('auto');
    q.level = 'high';
    for (let i = 0; i < QualityManager.WINDOW * 12; i++) q.sample(30);
    expect(q.level).not.toBe('high');
    expect(changes.some((c) => c.endsWith(':true'))).toBe(true);
  });

  it('quality recovers resolution when frames are fast, and ignores hitches', () => {
    const q = new QualityManager('medium', () => {});
    for (let i = 0; i < QualityManager.WINDOW * 2; i++) q.sample(30);
    const low = q.scale;
    for (let i = 0; i < QualityManager.WINDOW * 6; i++) q.sample(8);
    expect(q.scale).toBeGreaterThan(low);
    expect(q.scale).toBe(1);
    for (let i = 0; i < QualityManager.WINDOW * 3; i++) q.sample(5000);
    expect(q.scale).toBe(1);
    expect(q.pixelRatio(3)).toBe(PRESETS.medium.maxPixelRatio);
  });

  it('the game loop caps catch-up steps after a long pause', () => {
    const g = globalThis as Record<string, unknown>;
    let cb: ((t: number) => void) | null = null;
    let now = 0;
    g.requestAnimationFrame = (fn: (t: number) => void) => ((cb = fn), 1);
    g.cancelAnimationFrame = () => {};
    const realNow = performance.now;
    performance.now = () => now;
    let steps = 0;
    const loop = new GameLoop(() => steps++, () => {});
    loop.start();
    now = 5000; // tab was hidden for five seconds
    cb!(now);
    expect(steps).toBeLessThanOrEqual(GameLoop.MAX_STEPS);
    steps = 0;
    for (let f = 0; f < 30; f++) {
      now += 1000 / 30; // one second at 30 fps = sixty fixed steps
      cb!(now);
    }
    expect(steps).toBeGreaterThanOrEqual(59);
    expect(steps).toBeLessThanOrEqual(60);
    loop.stop();
    performance.now = realNow;
  });
});
