import type { RunSummary } from '../gameplay/Simulation';
import { UPGRADES, UPGRADE_IDS, zeroUpgrades, type UpgradeId, type UpgradeLevels } from '../gameplay/Upgrades';
import type { LevelConfig } from '../levels/LevelConfig';
import { LEVEL_COUNT } from '../levels/LevelGenerator';
import { ENDLESS_SCORE_CAP, type EndlessBest } from '../levels/Endless';
import { SKINS, defaultSkins, skinById, type SkinKind, type SkinState } from '../gameplay/Skins';

export type Screen = 'loading' | 'menu' | 'levels' | 'playing' | 'paused' | 'won' | 'lost' | 'upgrades' | 'settings' | 'leaderboard' | 'skins' | 'continue';
export type QualitySetting = 'auto' | 'low' | 'medium' | 'high';

export interface Settings {
  music: boolean;
  sfx: boolean;
  haptics: boolean;
  quality: QualitySetting;
}

export interface LevelBest {
  score: number;
  stars: number;
}

/** A score the host has not acknowledged yet (offline, bridge error). Retried on next launch. */
export interface PendingSubmission {
  runId: string;
  score: number;
  level: number;
}

export interface SaveData {
  version: 1;
  upgrades: UpgradeLevels;
  /** Highest level the player may start. */
  unlocked: number;
  best: Record<number, LevelBest>;
  settings: Settings;
  pending: PendingSubmission[];
  endless: EndlessBest;
  skins: SkinState;
}

export const SAVE_KEY = 'hash_rush_save_v1';

export function defaultSave(): SaveData {
  return {
    version: 1,
    upgrades: zeroUpgrades(),
    unlocked: 1,
    best: {},
    settings: { music: true, sfx: true, haptics: true, quality: 'auto' },
    pending: [],
    endless: { score: 0, stage: 0 },
    skins: defaultSkins(),
  };
}

type KV = Pick<Storage, 'getItem' | 'setItem'>;

const num = (v: unknown, fallback: number, min: number, max: number): number =>
  typeof v === 'number' && Number.isFinite(v) ? Math.min(max, Math.max(min, Math.floor(v))) : fallback;

/** Load and sanitise: a corrupt, tampered or older save never crashes the game. */
export function loadSave(storage: KV | null): SaveData {
  const save = defaultSave();
  let raw: unknown;
  try {
    raw = JSON.parse(storage?.getItem(SAVE_KEY) ?? 'null');
  } catch {
    return save;
  }
  if (!raw || typeof raw !== 'object') return save;
  const r = raw as Record<string, unknown>;
  save.unlocked = num(r.unlocked, 1, 1, LEVEL_COUNT);
  const up = (r.upgrades ?? {}) as Record<string, unknown>;
  for (const id of UPGRADE_IDS) save.upgrades[id] = num(up[id], 0, 0, UPGRADES[id].maxLevel);
  const best = (r.best ?? {}) as Record<string, { score?: unknown; stars?: unknown }>;
  for (const key of Object.keys(best)) {
    const level = Number(key);
    if (!Number.isInteger(level) || level < 1 || level > LEVEL_COUNT) continue;
    save.best[level] = { score: num(best[key]?.score, 0, 0, 1e7), stars: num(best[key]?.stars, 0, 0, 3) };
  }
  const s = (r.settings ?? {}) as Record<string, unknown>;
  save.settings.music = s.music !== false;
  save.settings.sfx = s.sfx !== false;
  save.settings.haptics = s.haptics !== false;
  if (s.quality === 'low' || s.quality === 'medium' || s.quality === 'high') save.settings.quality = s.quality;
  if (Array.isArray(r.pending)) {
    for (const p of r.pending.slice(-10) as Record<string, unknown>[]) {
      if (p && typeof p.runId === 'string') save.pending.push({ runId: p.runId, score: num(p.score, 0, 0, 1e7), level: num(p.level, 1, 1, LEVEL_COUNT) });
    }
  }
  const e = (r.endless ?? {}) as Record<string, unknown>;
  save.endless = { score: num(e.score, 0, 0, 1e8), stage: num(e.stage, 0, 0, 9999) };
  const sk = (r.skins ?? {}) as { army?: unknown; cannon?: unknown; owned?: Record<string, unknown> };
  for (const kind of ['army', 'cannon'] as const) {
    const owned = Array.isArray(sk.owned?.[kind]) ? (sk.owned![kind] as unknown[]) : [];
    for (const id of owned) {
      if (typeof id === 'string' && SKINS.some((s) => s.id === id) && !save.skins.owned[kind].includes(id)) save.skins.owned[kind].push(id);
    }
    const equipped = sk[kind];
    if (typeof equipped === 'string' && save.skins.owned[kind].includes(equipped)) save.skins[kind] = equipped;
  }
  return save;
}

/** Returns false when storage is unavailable (private mode, quota) — the game keeps running. */
export function storeSave(storage: KV | null, save: SaveData): boolean {
  try {
    storage?.setItem(SAVE_KEY, JSON.stringify(save));
    return storage != null;
  } catch {
    return false;
  }
}

export interface RunReward {
  newBest: boolean;
  unlockedLevel: number | null;
}

/**
 * Fold a finished run into the save. Only called with the final summary: a
 * run abandoned by reload or exit leaves the save untouched.
 */
export function applyRun(save: SaveData, level: LevelConfig, run: RunSummary): RunReward {
  const prev = save.best[level.id];
  let unlockedLevel: number | null = null;
  if (run.status === 'won' && level.id >= save.unlocked && level.id < LEVEL_COUNT) {
    save.unlocked = level.id + 1;
    unlockedLevel = save.unlocked;
  }
  const newBest = run.status === 'won' && (!prev || run.score > prev.score);
  if (run.status === 'won') {
    save.best[level.id] = { score: Math.max(prev?.score ?? 0, run.score), stars: Math.max(prev?.stars ?? 0, run.stars) };
  }
  return { newBest, unlockedLevel };
}

/*
 * Upgrades and skins are paid for in the host's currency (HashCoins in the
 * app). The host charges; these only record what was bought, so call them
 * after the host confirms payment.
 */

/** Raise an upgrade one level. Returns false when it is already maxed. */
export function grantUpgrade(save: SaveData, id: UpgradeId): boolean {
  const level = save.upgrades[id];
  if (level >= UPGRADES[id].maxLevel) return false;
  save.upgrades[id] = level + 1;
  return true;
}

export function ownsSkin(save: SaveData, kind: SkinKind, id: string): boolean {
  return save.skins.owned[kind].includes(skinById(id).id);
}

/** Equip a skin the player already owns. Returns false when they don't. */
export function equipSkin(save: SaveData, kind: SkinKind, id: string): boolean {
  if (!ownsSkin(save, kind, id)) return false;
  save.skins[kind] = skinById(id).id;
  return true;
}

/** Add a paid-for skin to the collection and equip it. */
export function grantSkin(save: SaveData, kind: SkinKind, id: string): void {
  const skin = skinById(id);
  if (!save.skins.owned[kind].includes(skin.id)) save.skins.owned[kind].push(skin.id);
  save.skins[kind] = skin.id;
}

/** Fold a finished endless run into the save. Returns true on a new best score. */
export function applyEndless(save: SaveData, score: number, stage: number): boolean {
  const better = score > save.endless.score;
  if (better) save.endless.score = Math.round(score);
  if (stage > save.endless.stage) save.endless.stage = stage;
  return better;
}

/** Career score: the best score on every level plus the best endless run (capped). This is what goes to the leaderboard. */
export function careerScore(save: SaveData): number {
  let total = 0;
  for (const key of Object.keys(save.best)) total += save.best[Number(key)]!.score;
  return total + Math.min(ENDLESS_SCORE_CAP, save.endless.score);
}
