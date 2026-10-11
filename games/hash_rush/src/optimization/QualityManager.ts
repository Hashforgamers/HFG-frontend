import type { QualitySetting } from '../core/GameState';

export type QualityLevel = 'low' | 'medium' | 'high';

export interface QualityPreset {
  level: QualityLevel;
  /** Upper bound on devicePixelRatio. */
  maxPixelRatio: number;
  /** Use the low-poly character meshes. */
  lowPolyCrowd: boolean;
  particles: number;
  /** Fraction of scenery props to build (0..1). */
  propDensity: number;
  ambientParticles: number;
  blobShadows: boolean;
  antialias: boolean;
  /** Soft glow on emissive surfaces (post-process). */
  bloom: boolean;
}

export const PRESETS: Record<QualityLevel, QualityPreset> = {
  low: { level: 'low', maxPixelRatio: 1, lowPolyCrowd: true, particles: 350, propDensity: 0.4, ambientParticles: 0, blobShadows: false, antialias: false, bloom: false },
  medium: { level: 'medium', maxPixelRatio: 1.5, lowPolyCrowd: true, particles: 800, propDensity: 0.7, ambientParticles: 140, blobShadows: true, antialias: false, bloom: true },
  high: { level: 'high', maxPixelRatio: 2, lowPolyCrowd: false, particles: 1500, propDensity: 1, ambientParticles: 320, blobShadows: true, antialias: true, bloom: true },
};

const ORDER: readonly QualityLevel[] = ['low', 'medium', 'high'];

/** First guess before anything has been measured. */
export function guessQuality(): QualityLevel {
  const nav = typeof navigator === 'undefined' ? undefined : (navigator as Navigator & { deviceMemory?: number });
  if (!nav) return 'medium';
  const mobile = /Android|iPhone|iPad|iPod/i.test(nav.userAgent);
  const cores = nav.hardwareConcurrency ?? 4;
  const memory = nav.deviceMemory ?? 4;
  if (mobile) return cores >= 8 && memory >= 6 ? 'medium' : cores <= 4 || memory <= 3 ? 'low' : 'medium';
  return cores >= 8 ? 'high' : 'medium';
}

/**
 * Adaptive quality. Every window of frames it compares the average frame
 * time with the budget:
 *   too slow  -> lower the resolution scale, and once that bottoms out, drop a preset;
 *   headroom  -> raise the resolution scale back (presets only ever step down
 *                automatically, to avoid oscillating).
 * A fixed setting ('low' | 'medium' | 'high') disables preset changes but
 * keeps the resolution scale adaptive.
 */
export class QualityManager {
  static readonly WINDOW = 90;
  static readonly SLOW_MS = 21;
  static readonly FAST_MS = 13.5;
  static readonly MIN_SCALE = 0.6;

  level: QualityLevel;
  /** Multiplier on the pixel ratio, MIN_SCALE..1. */
  scale = 1;
  private sum = 0;
  private frames = 0;
  private slowWindows = 0;
  private auto: boolean;

  constructor(setting: QualitySetting, private readonly onChange: (preset: QualityPreset, presetChanged: boolean) => void) {
    this.auto = setting === 'auto';
    this.level = setting === 'auto' ? guessQuality() : setting;
  }

  get preset(): QualityPreset {
    return PRESETS[this.level];
  }

  pixelRatio(devicePixelRatio: number): number {
    return Math.max(0.5, Math.min(devicePixelRatio, this.preset.maxPixelRatio) * this.scale);
  }

  set(setting: QualitySetting): void {
    this.auto = setting === 'auto';
    const next = setting === 'auto' ? guessQuality() : setting;
    const changed = next !== this.level;
    this.level = next;
    this.scale = 1;
    this.slowWindows = 0;
    this.onChange(this.preset, changed);
  }

  /** Feed one frame's duration. Ignores hitches so a single GC pause doesn't trigger a downgrade. */
  sample(frameMs: number): void {
    if (frameMs > 120) return;
    this.sum += frameMs;
    if (++this.frames < QualityManager.WINDOW) return;
    const avg = this.sum / this.frames;
    this.sum = 0;
    this.frames = 0;
    if (avg > QualityManager.SLOW_MS) {
      this.slowWindows++;
      if (this.scale > QualityManager.MIN_SCALE + 0.01) {
        this.scale = Math.max(QualityManager.MIN_SCALE, this.scale - 0.15);
        this.onChange(this.preset, false);
      } else if (this.auto && this.slowWindows >= 3 && this.level !== 'low') {
        this.level = ORDER[ORDER.indexOf(this.level) - 1]!;
        this.scale = 1;
        this.slowWindows = 0;
        this.onChange(this.preset, true);
      }
    } else {
      this.slowWindows = 0;
      if (avg < QualityManager.FAST_MS && this.scale < 1) {
        this.scale = Math.min(1, this.scale + 0.1);
        this.onChange(this.preset, false);
      }
    }
  }
}
