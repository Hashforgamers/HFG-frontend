import { CANNON_HP, CANNON_SPEED, FX, FxQueue, TRACK_HALF, clamp } from './constants';
import type { PlayerStats } from './Upgrades';

export const OVERDRIVE_TIME = 4;
export const OVERDRIVE_MULT = 3;

/** The player's hover cannon: slides across the track, advances on its own, fires on a timer. */
export class Cannon {
  x = 0;
  z = 0;
  hp = CANNON_HP;
  readonly maxHp = CANNON_HP;
  /** 1 right after a shot, decays to 0 (drives the recoil animation). */
  recoil = 0;
  /** Seconds of Overdrive left. */
  overdrive = 0;
  /** Seconds until Overdrive is ready again. */
  abilityCd = 0;
  blocked = false;
  /** 1 right after taking damage, decays. */
  hurt = 0;
  shots = 0;
  /** Seconds of invulnerability left (after a revive). */
  shield = 0;
  private fireT = 0.4;

  constructor(private readonly stats: PlayerStats) {}

  /** Returns how many pods to launch this tick (0 or 1 in practice). */
  update(dt: number, aimX: number, ability: boolean, stopZ: number, blockerZ: number, fx: FxQueue): number {
    const limit = TRACK_HALF - 0.9;
    if (!Number.isFinite(aimX)) aimX = aimX > 0 ? limit : aimX < 0 ? -limit : this.x;
    this.x += (clamp(aimX, -limit, limit) - this.x) * Math.min(1, dt * 20);
    // hold position while enemies are close ahead
    const maxZ = Math.min(stopZ, blockerZ - 6);
    this.blocked = this.z >= maxZ;
    if (!this.blocked) this.z = Math.min(maxZ, this.z + CANNON_SPEED * dt);

    if (this.abilityCd > 0) this.abilityCd = Math.max(0, this.abilityCd - dt);
    if (this.overdrive > 0) this.overdrive = Math.max(0, this.overdrive - dt);
    if (ability && this.abilityCd <= 0) {
      this.overdrive = OVERDRIVE_TIME;
      this.abilityCd = this.stats.abilityCooldown;
      fx.push(FX.Ability, this.x, this.z);
    }
    if (this.recoil > 0) this.recoil = Math.max(0, this.recoil - dt * 9);
    if (this.hurt > 0) this.hurt = Math.max(0, this.hurt - dt * 3);
    if (this.shield > 0) this.shield = Math.max(0, this.shield - dt);

    let pods = 0;
    this.fireT -= dt;
    const interval = 1 / (this.stats.fireRate * (this.overdrive > 0 ? OVERDRIVE_MULT : 1));
    while (this.fireT <= 0) {
      this.fireT += interval;
      pods++;
    }
    if (pods > 0) {
      this.recoil = 1;
      this.shots += pods;
      fx.push(FX.Muzzle, this.x, this.z + 1.8);
    }
    return pods;
  }

  takeDamage(dmg: number, fx: FxQueue): void {
    if (dmg <= 0 || this.hp <= 0 || this.shield > 0) return;
    this.hp = Math.max(0, this.hp - dmg);
    if (this.hurt < 0.4) fx.push(FX.CannonHit, this.x, this.z, dmg);
    this.hurt = 1;
  }
}
