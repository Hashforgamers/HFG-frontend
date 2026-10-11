import { Rng } from '../core/Rng';
import type { BossDef, BossKind } from '../levels/LevelConfig';
import { AgentState, CrowdSystem } from './CrowdSystem';
import { EnemySystem } from './EnemySystem';
import type { PodTarget } from './ProjectileSystem';
import { FX, FxQueue, TRACK_HALF, clamp } from './constants';

export const BossState = { Dormant: 0, Intro: 1, Fight: 2, Dying: 3, Dead: 4 } as const;
export type BossAttack = 'slam' | 'boulder' | 'stomp' | 'flame' | 'fireball' | 'summon' | 'orbs' | 'beam' | 'blink';

export interface BossStats {
  name: string;
  radius: number;
  /** Damage per second dealt to units in melee contact. */
  meleeDps: number;
  /** Seconds between attacks. */
  interval: number;
  cycle: readonly BossAttack[];
}

export const BOSS_STATS: Record<BossKind, BossStats> = {
  titan: { name: 'Iron Titan', radius: 2.3, meleeDps: 9, interval: 3.4, cycle: ['slam', 'boulder', 'stomp', 'slam', 'boulder'] },
  inferno: { name: 'Inferno Guardian', radius: 2.7, meleeDps: 11, interval: 3.1, cycle: ['flame', 'fireball', 'summon', 'flame', 'fireball'] },
  void: { name: 'Void Commander', radius: 2.0, meleeDps: 12, interval: 2.8, cycle: ['orbs', 'beam', 'blink', 'orbs', 'summon', 'beam'] },
};

export const INTRO_TIME = 2.6;
export const DEATH_TIME = 2.4;
/** After this long in the fight the boss overloads: every cast also hits the cannon. No stalemates. */
export const OVERLOAD_TIME = 50;
const MAX_TELEGRAPHS = 12;

/** A warned area attack: drawn on the ground for `delay` seconds, then it lands. */
export interface Telegraph {
  live: boolean;
  /** 0 = circle (hw = radius), 1 = rectangle (hw × hd half extents). */
  shape: 0 | 1;
  x: number;
  z: number;
  hw: number;
  hd: number;
  t: number;
  delay: number;
  cannonDmg: number;
}

/** Giant end-of-level boss with telegraphed attack patterns. */
export class BossSystem implements PodTarget {
  readonly stats: BossStats;
  readonly kind: BossKind;
  readonly tier: number;
  x = 0;
  readonly z: number;
  hp: number;
  readonly maxHp: number;
  state: number = BossState.Dormant;
  /** Seconds in the current state. */
  t = 0;
  flash = 0;
  shield = 0;
  shieldMax = 0;
  private shieldT = 0;
  attackers = 0;
  attackersPrev = 0;
  /** Last attack started and seconds since (for the view's animation). */
  attack: BossAttack | null = null;
  attackT = 99;
  casts = 0;
  readonly telegraphs: Telegraph[] = [];
  /** Damage dealt to the cannon this tick. */
  cannonDamage = 0;
  private cooldown: number;
  private step = 0;

  constructor(def: BossDef, z: number, private readonly rng: Rng) {
    this.kind = def.kind;
    this.tier = def.tier;
    this.stats = BOSS_STATS[def.kind];
    this.z = z;
    this.hp = this.maxHp = def.hp;
    this.cooldown = 2;
    for (let i = 0; i < MAX_TELEGRAPHS; i++) {
      this.telegraphs.push({ live: false, shape: 0, x: 0, z: 0, hw: 0, hd: 0, t: 0, delay: 1, cannonDmg: 0 });
    }
  }

  get targetable(): boolean {
    return this.state === BossState.Fight;
  }

  get overloaded(): boolean {
    return this.state === BossState.Fight && this.t > OVERLOAD_TIME;
  }

  get enraged(): boolean {
    return this.hp < this.maxHp * 0.3;
  }

  hit(dmg: number, fx: FxQueue): void {
    if (!this.targetable || dmg <= 0) return;
    if (this.shield > 0) {
      this.shield -= dmg;
      if (this.shield <= 0) {
        this.shield = 0;
        fx.push(FX.BossShield, this.x, this.z, 0);
      }
      return;
    }
    this.hp -= dmg;
    if (this.flash < 0.05) this.flash = 1;
    if (this.hp <= 0) {
      this.hp = 0;
      this.state = BossState.Dying;
      this.t = 0;
      for (const tg of this.telegraphs) tg.live = false;
      fx.push(FX.BossDie, this.x, this.z);
    }
  }

  podHit(x: number, z: number, dmg: number, fx: FxQueue): boolean {
    if (!this.targetable || Math.hypot(x - this.x, z - this.z) > this.stats.radius + 0.3) return false;
    this.hit(dmg, fx);
    fx.push(FX.BossHit, x, z);
    return true;
  }

  private warn(shape: 0 | 1, x: number, z: number, hw: number, hd: number, delay: number, cannonDmg: number): void {
    for (const tg of this.telegraphs) {
      if (tg.live) continue;
      tg.live = true;
      tg.shape = shape;
      tg.x = x;
      tg.z = z;
      tg.hw = hw;
      tg.hd = hd;
      tg.t = 0;
      tg.delay = delay;
      tg.cannonDmg = cannonDmg * (0.85 + 0.15 * this.tier);
      return;
    }
  }

  private cast(kind: BossAttack, cannonX: number, cannonZ: number, crowd: CrowdSystem, enemies: EnemySystem, fx: FxQueue): void {
    this.attack = kind;
    this.attackT = 0;
    this.casts++;
    fx.push(FX.BossAttack, this.x, this.z, this.casts);
    const lane = TRACK_HALF - 0.4;
    switch (kind) {
      case 'slam': {
        // aim at a unit near the boss, otherwise the ground in front of it
        let tx = this.x;
        let tz = this.z - 5;
        for (let k = 0; k < 12; k++) {
          const a = this.rng.int(0, crowd.cap - 1);
          if (crowd.isActive(a) && this.z - crowd.z[a]! < 16) {
            tx = crowd.x[a]!;
            tz = crowd.z[a]!;
            break;
          }
        }
        this.warn(0, tx, tz, 2.6, 2.6, 1.3, 0);
        break;
      }
      case 'boulder':
        this.warn(0, cannonX, cannonZ, 1.9, 1.9, 1.5, 20);
        break;
      case 'stomp':
        // two shockwave strips, each leaving half the track open
        this.warn(1, -lane / 2, this.z - 5.5, lane / 2, 1.5, 1.1, 0);
        this.warn(1, lane / 2, this.z - 10, lane / 2, 1.5, 1.7, 0);
        break;
      case 'flame': {
        const side = this.rng.next() < 0.5 ? -1 : 1;
        this.warn(1, side * (lane / 2), this.z - 9.5, lane / 2, 8, 1.5, 0);
        break;
      }
      case 'fireball': {
        const off = this.rng.next() < 0.5 ? -2.6 : 2.6;
        this.warn(0, cannonX, cannonZ, 1.8, 1.8, 1.4, 18);
        this.warn(0, clamp(cannonX + off, -lane, lane), cannonZ, 1.8, 1.8, 1.9, 18);
        break;
      }
      case 'orbs':
        for (let k = 0; k < 3; k++) {
          this.warn(0, clamp(cannonX + (k - 1) * this.rng.range(1.8, 2.8), -lane, lane), cannonZ, 1.6, 1.6, 1.2 + k * 0.45, 16);
        }
        break;
      case 'beam': {
        const len = (this.z - cannonZ) / 2;
        this.warn(1, this.x, this.z - len, 1.4, len, 1.4, 24);
        break;
      }
      case 'blink': {
        const spots = [-3, 0, 3].filter((s) => Math.abs(s - this.x) > 1);
        this.x = this.rng.pick(spots);
        this.shieldMax = this.shield = this.maxHp * 0.1;
        this.shieldT = 8;
        fx.push(FX.BossShield, this.x, this.z, 1);
        break;
      }
      case 'summon': {
        const n = 4 + Math.round(this.tier * 2);
        for (let k = 0; k < n; k++) {
          const ex = ((k + 0.5) / n - 0.5) * 2 * (lane - 0.5);
          enemies.spawn(this.kind === 'void' && k % 3 === 0 ? 'brute' : 'grunt', ex, this.z - 3.5 - (k % 2), true);
        }
        fx.push(FX.Summon, this.x, this.z - 3.5);
        break;
      }
    }
  }

  private land(tg: Telegraph, cannonX: number, cannonZ: number, crowd: CrowdSystem, fx: FxQueue): void {
    fx.push(FX.Explosion, tg.x, tg.z, tg.shape === 0 ? tg.hw : Math.min(tg.hw, tg.hd) + 1);
    const inside = (x: number, z: number, pad: number) =>
      tg.shape === 0
        ? Math.hypot(x - tg.x, z - tg.z) < tg.hw + pad
        : Math.abs(x - tg.x) < tg.hw + pad && Math.abs(z - tg.z) < tg.hd + pad;
    for (let i = 0; i < crowd.cap; i++) {
      if (crowd.isActive(i) && inside(crowd.x[i]!, crowd.z[i]!, 0)) crowd.kill(i, AgentState.Die, fx);
    }
    if (tg.cannonDmg > 0 && inside(cannonX, cannonZ, 0.5)) this.cannonDamage += tg.cannonDmg;
  }

  update(dt: number, cannonX: number, cannonZ: number, crowd: CrowdSystem, enemies: EnemySystem, fx: FxQueue): void {
    this.t += dt;
    this.attackT += dt;
    this.cannonDamage = 0;
    if (this.flash > 0) this.flash = Math.max(0, this.flash - dt * 5);
    this.attackersPrev = this.attackers;
    this.attackers = 0;
    switch (this.state) {
      case BossState.Dormant:
        if (this.z - cannonZ < 34) {
          this.state = BossState.Intro;
          this.t = 0;
          fx.push(FX.BossIntro, this.x, this.z);
        }
        return;
      case BossState.Intro:
        if (this.t >= INTRO_TIME) {
          this.state = BossState.Fight;
          this.t = 0;
        }
        return;
      case BossState.Dying:
        if (this.t >= DEATH_TIME) this.state = BossState.Dead;
        return;
      case BossState.Dead:
        return;
    }
    if (this.shield > 0) {
      this.shieldT -= dt;
      if (this.shieldT <= 0) this.shield = 0;
    }
    this.cooldown -= dt;
    if (this.cooldown <= 0) {
      const cycle = this.stats.cycle;
      this.cast(cycle[this.step++ % cycle.length]!, cannonX, cannonZ, crowd, enemies, fx);
      if (this.overloaded) {
        this.cannonDamage += 9 * this.tier;
        fx.push(FX.Explosion, cannonX, cannonZ, 2);
      }
      this.cooldown = (this.stats.interval / (0.85 + 0.15 * this.tier)) * (this.enraged ? 0.7 : 1);
    }
    for (const tg of this.telegraphs) {
      if (!tg.live) continue;
      tg.t += dt;
      if (tg.t >= tg.delay) {
        tg.live = false;
        this.land(tg, cannonX, cannonZ, crowd, fx);
      }
    }
  }
}
