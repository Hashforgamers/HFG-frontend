export type SkinKind = 'army' | 'cannon';

/**
 * A skin recolours a model: every base colour is shifted in HSL space and the
 * glowing parts (visor, light strips) take the accent colour. No reds — red
 * is reserved for the enemy.
 */
export interface SkinDef {
  id: string;
  name: string;
  /** Sample price for the offline mock (the app sets the real one); 0 = owned from the start. */
  price: number;
  /** Hue shift, 0..1 (wraps). */
  hue: number;
  /** Saturation and lightness multipliers. */
  sat: number;
  light: number;
  accent: number;
  /** CSS colours for the shop swatch. */
  swatch: [string, string];
}

export const SKINS: readonly SkinDef[] = [
  { id: 'classic', name: 'Hash Blue', price: 0, hue: 0, sat: 1, light: 1, accent: 0x40f2ff, swatch: ['#2b7bff', '#40f2ff'] },
  { id: 'emerald', name: 'Emerald', price: 150, hue: -0.25, sat: 1, light: 1, accent: 0xc8ff5a, swatch: ['#19c46a', '#c8ff5a'] },
  { id: 'royal', name: 'Royal Violet', price: 300, hue: 0.14, sat: 1, light: 1.05, accent: 0xff8cf5, swatch: ['#8a3dff', '#ff8cf5'] },
  { id: 'arctic', name: 'Arctic', price: 500, hue: 0, sat: 0.14, light: 2.3, accent: 0x4fd8ff, swatch: ['#eef4ff', '#4fd8ff'] },
  { id: 'shadow', name: 'Shadow Ops', price: 800, hue: 0, sat: 0.3, light: 0.32, accent: 0x8dff4a, swatch: ['#1c2233', '#8dff4a'] },
  { id: 'gold', name: 'Solid Gold', price: 1200, hue: -0.49, sat: 1.1, light: 1.12, accent: 0xfff3b0, swatch: ['#f5b21a', '#fff3b0'] },
];

export function skinById(id: string): SkinDef {
  return SKINS.find((s) => s.id === id) ?? SKINS[0]!;
}

export interface SkinState {
  army: string;
  cannon: string;
  owned: Record<SkinKind, string[]>;
}

export function defaultSkins(): SkinState {
  return { army: 'classic', cannon: 'classic', owned: { army: ['classic'], cannon: ['classic'] } };
}

/** Recolour one RGB triple (0..1, linear) in place. */
export function recolor(rgb: { r: number; g: number; b: number }, skin: SkinDef): void {
  if (skin.hue === 0 && skin.sat === 1 && skin.light === 1) return;
  const max = Math.max(rgb.r, rgb.g, rgb.b);
  const min = Math.min(rgb.r, rgb.g, rgb.b);
  let h = 0;
  let s = 0;
  let l = (max + min) / 2;
  const d = max - min;
  if (d > 1e-6) {
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    if (max === rgb.r) h = ((rgb.g - rgb.b) / d + (rgb.g < rgb.b ? 6 : 0)) / 6;
    else if (max === rgb.g) h = ((rgb.b - rgb.r) / d + 2) / 6;
    else h = ((rgb.r - rgb.g) / d + 4) / 6;
  }
  h = (((h + skin.hue) % 1) + 1) % 1;
  s = Math.min(1, s * skin.sat);
  l = Math.min(0.92, l * skin.light);
  const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
  const p = 2 * l - q;
  const ch = (t: number) => {
    t = ((t % 1) + 1) % 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  };
  rgb.r = ch(h + 1 / 3);
  rgb.g = ch(h);
  rgb.b = ch(h - 1 / 3);
}
