export type UpgradeId = 'fireRate' | 'startArmy' | 'unitDamage' | 'unitHealth' | 'cannonPower' | 'abilityCooldown';

export interface UpgradeDef {
  id: UpgradeId;
  name: string;
  desc: string;
  maxLevel: number;
  baseCost: number;
  costGrowth: number;
  /** Gameplay value at a given upgrade level (level 0 = not upgraded). */
  value(level: number): number;
  format(value: number): string;
}

export const UPGRADES: Record<UpgradeId, UpgradeDef> = {
  fireRate: {
    id: 'fireRate', name: 'Fire Rate', desc: 'Pods launched per second',
    maxLevel: 15, baseCost: 60, costGrowth: 1.32,
    value: (l) => 2.4 + 0.3 * l, format: (v) => `${v.toFixed(1)}/s`,
  },
  startArmy: {
    id: 'startArmy', name: 'Starting Army', desc: 'Units deployed at level start',
    maxLevel: 15, baseCost: 50, costGrowth: 1.3,
    value: (l) => 3 * l, format: (v) => `${v}`,
  },
  unitDamage: {
    id: 'unitDamage', name: 'Unit Damage', desc: 'Damage per second per unit',
    maxLevel: 15, baseCost: 70, costGrowth: 1.34,
    value: (l) => 10 + 1.5 * l, format: (v) => v.toFixed(1),
  },
  unitHealth: {
    id: 'unitHealth', name: 'Unit Armor', desc: 'Hit points per unit',
    maxLevel: 15, baseCost: 70, costGrowth: 1.34,
    value: (l) => 10 + 1.5 * l, format: (v) => v.toFixed(1),
  },
  cannonPower: {
    id: 'cannonPower', name: 'Cannon Power', desc: 'Direct-hit pod damage',
    maxLevel: 15, baseCost: 60, costGrowth: 1.32,
    value: (l) => 14 + 6 * l, format: (v) => `${v}`,
  },
  abilityCooldown: {
    id: 'abilityCooldown', name: 'Overdrive', desc: 'Cooldown of the rapid-fire burst',
    maxLevel: 10, baseCost: 90, costGrowth: 1.4,
    value: (l) => 24 - 1.4 * l, format: (v) => `${v.toFixed(1)}s`,
  },
};

export const UPGRADE_IDS = Object.keys(UPGRADES) as UpgradeId[];
export type UpgradeLevels = Record<UpgradeId, number>;

export function zeroUpgrades(): UpgradeLevels {
  return { fireRate: 0, startArmy: 0, unitDamage: 0, unitHealth: 0, cannonPower: 0, abilityCooldown: 0 };
}

/** Sample price for the offline mock; in the app the host's price list is what is charged and shown. */
export function upgradeCost(id: UpgradeId, level: number): number {
  const def = UPGRADES[id];
  return Math.round((def.baseCost * Math.pow(def.costGrowth, level)) / 5) * 5;
}

/** The numbers the simulation actually reads. */
export interface PlayerStats {
  fireRate: number;
  startArmy: number;
  unitDamage: number;
  unitHealth: number;
  podDamage: number;
  abilityCooldown: number;
}

export function computeStats(levels: UpgradeLevels): PlayerStats {
  const v = (id: UpgradeId) => UPGRADES[id].value(Math.min(Math.max(0, levels[id] | 0), UPGRADES[id].maxLevel));
  return {
    fireRate: v('fireRate'),
    startArmy: v('startArmy'),
    unitDamage: v('unitDamage'),
    unitHealth: v('unitHealth'),
    podDamage: v('cannonPower'),
    abilityCooldown: v('abilityCooldown'),
  };
}
