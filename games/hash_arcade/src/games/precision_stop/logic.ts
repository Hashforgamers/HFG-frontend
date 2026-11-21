import type { Rng } from '../../engine/rng';

/** 0 → 1 → 0 sweep: phase in cycles. */
export const triangle = (phase: number) => {
  const f = phase - Math.floor(phase);
  return f < 0.5 ? f * 2 : 2 - f * 2;
};

export interface Zone {
  center: number;
  width: number;
  /** Sweeps per second. */
  speed: number;
}

export function makeZone(level: number, rng: Rng): Zone {
  const width = Math.max(0.05, 0.24 - level * 0.012);
  const center = width / 2 + 0.05 + rng() * (0.9 - width);
  return { center, width, speed: Math.min(1.6, 0.35 + level * 0.06) };
}

export interface Judgement {
  inZone: boolean;
  perfect: boolean;
  points: number;
}

/** 100 at the zone edge up to 200 dead centre. */
export function judge(pos: number, zone: Zone): Judgement {
  const dist = Math.abs(pos - zone.center);
  const half = zone.width / 2;
  if (dist > half) return { inZone: false, perfect: false, points: 0 };
  const closeness = 1 - dist / half;
  return { inZone: true, perfect: closeness > 0.85, points: Math.round(100 + 100 * closeness) };
}
