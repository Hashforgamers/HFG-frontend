import { describe, expect, it } from 'vitest';
import { SAVE_KEY, applyEndless, careerScore, defaultSave, equipSkin, grantSkin, loadSave, ownsSkin, storeSave } from '../src/core/GameState';
import { Simulation } from '../src/gameplay/Simulation';
import { SKINS, recolor, skinById } from '../src/gameplay/Skins';
import { computeStats, zeroUpgrades } from '../src/gameplay/Upgrades';
import { ENDLESS_MAX_CARRY, ENDLESS_SCORE_CAP, endlessStage } from '../src/levels/Endless';
import { isBadGate } from '../src/levels/LevelConfig';
import { getLevel, validateLevel } from '../src/levels/LevelManager';
import { botAim, playLevel } from './bot';

const stats = computeStats(zeroUpgrades());
class MemoryStorage {
  data = new Map<string, string>();
  getItem(k: string) {
    return this.data.get(k) ?? null;
  }
  setItem(k: string, v: string) {
    this.data.set(k, v);
  }
}

describe('skins', () => {
  it('the starter skin is free and owned; the rest are priced and avoid enemy red', () => {
    expect(SKINS[0]!.price).toBe(0);
    expect(new Set(SKINS.map((s) => s.id)).size).toBe(SKINS.length);
    for (const skin of SKINS.slice(1)) expect(skin.price).toBeGreaterThan(0);
    for (const skin of SKINS) {
      const c = { r: 0.07, g: 0.33, b: 0.95 }; // the unit's base blue
      recolor(c, skin);
      const redDominant = c.r > 0.5 && c.r > c.g * 1.8 && c.r > c.b * 1.8;
      expect(redDominant, skin.id).toBe(false);
      for (const v of [c.r, c.g, c.b]) expect(v >= 0 && v <= 1, skin.id).toBe(true);
    }
  });

  it('the classic skin leaves colours untouched', () => {
    const c = { r: 0.2, g: 0.4, b: 0.6 };
    recolor(c, skinById('classic'));
    expect(c).toEqual({ r: 0.2, g: 0.4, b: 0.6 });
    expect(skinById('nope').id).toBe('classic');
  });

  it('an unowned skin cannot be equipped; a granted one is owned and equipped; army and cannon are separate', () => {
    const save = defaultSave();
    expect(equipSkin(save, 'army', 'emerald')).toBe(false);
    expect(save.skins.army).toBe('classic');
    grantSkin(save, 'army', 'emerald');
    expect(save.skins.army).toBe('emerald');
    expect(save.skins.cannon).toBe('classic');
    expect(equipSkin(save, 'army', 'classic')).toBe(true);
    expect(equipSkin(save, 'army', 'emerald')).toBe(true);
    grantSkin(save, 'army', 'emerald');
    expect(save.skins.owned.army).toEqual(['classic', 'emerald']);
    expect(ownsSkin(save, 'cannon', 'emerald')).toBe(false);
  });

  it('skins survive a save round trip and tampering is dropped', () => {
    const storage = new MemoryStorage();
    const save = defaultSave();
    grantSkin(save, 'cannon', 'gold');
    storeSave(storage, save);
    expect(loadSave(storage).skins).toEqual(save.skins);
    storage.data.set(SAVE_KEY, JSON.stringify({ skins: { army: 'gold', cannon: 'hacked', owned: { army: ['classic'], cannon: ['hacked', 42, 'royal'] } } }));
    const loaded = loadSave(storage);
    expect(loaded.skins.army).toBe('classic'); // equipped but not owned
    expect(loaded.skins.cannon).toBe('classic');
    expect(loaded.skins.owned.cannon).toEqual(['classic', 'royal']);
  });
});

describe('endless mode', () => {
  it('every stage is a valid level, and stages get harder', () => {
    for (let k = 1; k <= 25; k++) expect(validateLevel(endlessStage(k)), `stage ${k}`).toEqual([]);
    expect(endlessStage(8).enemyHpScale).toBeGreaterThan(endlessStage(2).enemyHpScale);
    expect(endlessStage(8).boss.tier).toBeGreaterThan(endlessStage(1).boss.tier);
    expect(endlessStage(3).reward.credits).toBeGreaterThan(endlessStage(1).reward.credits);
    expect(JSON.stringify(endlessStage(4))).toBe(JSON.stringify(endlessStage(4)));
  });

  it('cannon health and survivors carry into the next stage', () => {
    const sim = new Simulation(endlessStage(2), stats, { startHp: 42, extraArmy: ENDLESS_MAX_CARRY });
    expect(sim.cannon.hp).toBe(42);
    expect(sim.crowd.count).toBe(ENDLESS_MAX_CARRY);
    expect(new Simulation(endlessStage(2), stats, { startHp: 500 }).cannon.hp).toBe(100);
    expect(new Simulation(endlessStage(2), stats, { startHp: -5 }).cannon.hp).toBe(1);
  });

  it('a run can be chained across stages and always ends', () => {
    let hp = 100;
    let army = 0;
    let stage = 1;
    let total = 0;
    for (; stage <= 40; stage++) {
      const sim = new Simulation(endlessStage(stage), stats, { startHp: hp, extraArmy: army });
      for (let i = 0; i < 600 * 60 && sim.status === 'playing'; i++) sim.step({ aimX: botAim(sim, 'good'), ability: sim.boss.targetable });
      total += sim.score();
      expect(sim.status).not.toBe('playing');
      if (sim.status === 'lost') break;
      hp = sim.cannon.hp + 25;
      army = Math.min(ENDLESS_MAX_CARRY, sim.crowd.count);
    }
    expect(stage).toBeGreaterThan(1); // un-upgraded bot clears at least the first stage
    expect(stage).toBeLessThanOrEqual(40); // ...and cannot go forever
    expect(total).toBeGreaterThan(0);
  });

  it('keeps the best score and furthest stage, and feeds the career score (capped)', () => {
    const save = defaultSave();
    expect(applyEndless(save, 9000, 3)).toBe(true);
    expect(applyEndless(save, 4000, 5)).toBe(false);
    expect(save.endless).toEqual({ score: 9000, stage: 5 });
    expect(careerScore(save)).toBe(9000);
    applyEndless(save, 9e6, 60);
    expect(careerScore(save)).toBe(ENDLESS_SCORE_CAP);
    const storage = new MemoryStorage();
    storeSave(storage, save);
    expect(loadSave(storage).endless).toEqual(save.endless);
  });
});

describe('bad gates in levels', () => {
  it('levels 1 and 2 have none; later levels do; a bad gate is never the only choice in its row', () => {
    expect(getLevel(1).gates.some((g) => isBadGate(g.op))).toBe(false);
    expect(getLevel(2).gates.some((g) => isBadGate(g.op))).toBe(false);
    let withBad = 0;
    for (let n = 1; n <= 30; n++) {
      const level = getLevel(n);
      if (level.gates.some((g) => isBadGate(g.op))) withBad++;
      for (const g of level.gates) {
        if (!isBadGate(g.op)) continue;
        expect(level.gates.some((o) => o.z === g.z && !isBadGate(o.op)), `level ${n} z=${g.z}`).toBe(true);
        expect(g.moveAmp ?? 0).toBe(0);
      }
    }
    expect(withBad).toBeGreaterThan(10);
  });

  it('lining the cannon up with the good gate keeps the whole army out of the bad one', () => {
    const level = getLevel(4); // row at z=100: ÷2 on the left, ×3 on the right
    const good = playLevel(level, stats, 'good');
    const bad = level.gates.findIndex((g) => isBadGate(g.op));
    const sim = new Simulation(level, stats);
    for (let i = 0; i < 60 * 45 && sim.cannon.z < 104; i++) sim.step({ aimX: botAim(sim, 'good'), ability: false });
    expect(sim.gates.gates[bad]!.lost).toBe(0);
    expect(good.status).not.toBe('playing');
  });

  it('walking into a bad gate costs units', () => {
    const level = getLevel(4);
    const bad = level.gates.findIndex((g) => isBadGate(g.op));
    const sim = new Simulation(level, stats);
    for (let i = 0; i < 60 * 45 && sim.cannon.z < 104; i++) sim.step({ aimX: botAim(sim, 'poor'), ability: false });
    expect(sim.gates.gates[bad]!.lost).toBeGreaterThan(0);
  });
});

describe('continue (revive)', () => {
  const lose = () => {
    const sim = playLevel(getLevel(5), stats, 'idle');
    expect(sim.status).toBe('lost');
    return sim;
  };

  it('brings the cannon back with health, a shield and room to breathe, keeping progress and score', () => {
    const sim = lose();
    const z = sim.cannon.z;
    const score = sim.score();
    const killed = sim.enemies.killed;
    expect(sim.revive()).toBe(true);
    expect(sim.status).toBe('playing');
    expect(sim.cannon.hp).toBe(60);
    expect(sim.cannon.z).toBe(z);
    expect(sim.score()).toBeGreaterThanOrEqual(score);
    expect(sim.enemies.killed).toBeGreaterThanOrEqual(killed); // the shockwave clears any attackers
    expect(sim.continues).toBe(1);
    const hp = sim.cannon.hp;
    for (let i = 0; i < 120; i++) sim.step({ aimX: 0, ability: false });
    expect(sim.cannon.hp).toBe(hp); // shielded for the first seconds
    expect(sim.status).toBe('playing');
  });

  it('does nothing unless the run was lost', () => {
    const fresh = new Simulation(getLevel(1), stats);
    expect(fresh.revive()).toBe(false);
    const won = playLevel(getLevel(1), stats, 'good');
    expect(won.revive()).toBe(false);
    expect(won.status).toBe('won');
  });

  it('a revived run can still be lost again', () => {
    const sim = lose();
    sim.revive();
    for (let i = 0; i < 600 * 60 && sim.status === 'playing'; i++) sim.step({ aimX: 0, ability: false });
    expect(sim.status).toBe('lost');
  });
});

describe('continue payment (mock host)', () => {
  it('sells upgrades and skins from the host price list and never charges for a failed purchase', async () => {
    const { MockAdapter } = await import('../src/integration/MockAdapter');
    const host = new MockAdapter({ latencyMs: 0 });
    const shop = (await host.shopCatalog())!;
    expect(shop.upgrades.fireRate).toHaveLength(15);
    expect(shop.skins.classic).toBeUndefined();
    host.wallet = shop.upgrades.fireRate![0]! + shop.skins.emerald! - 1;
    expect(await host.buyItem({ kind: 'upgrade', id: 'fireRate', level: 0 })).toEqual({ ok: true, balance: shop.skins.emerald! - 1 });
    expect((await host.buyItem({ kind: 'skin', slot: 'army', id: 'emerald' })).ok).toBe(false);
    expect((await host.buyItem({ kind: 'upgrade', id: 'fireRate', level: 15 })).ok).toBe(false);
    expect((await host.buyItem({ kind: 'skin', slot: 'army', id: 'nope' })).ok).toBe(false);
    expect(host.wallet).toBe(shop.skins.emerald! - 1);
  });

  it('quotes a price, charges it, and refuses when the wallet is short or the network is down', async () => {
    const { MockAdapter } = await import('../src/integration/MockAdapter');
    const host = new MockAdapter();
    expect((await host.continueOffer())?.cost).toBe(1000);
    host.wallet = 1500;
    expect(await host.payContinue()).toBe(true);
    expect(host.wallet).toBe(500);
    expect(await host.payContinue()).toBe(false);
    expect(host.wallet).toBe(500);
    host.wallet = 5000;
    host.options.offline = true;
    await expect(host.payContinue()).rejects.toThrow();
    expect(host.wallet).toBe(5000);
  });
});
