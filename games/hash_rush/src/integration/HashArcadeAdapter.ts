/**
 * The contract between HASH RUSH and whatever hosts it (Hash Arcade's
 * WebView, a web page, nothing at all). The game only ever talks to this
 * interface. See docs/INTEGRATION.md.
 *
 * Trust model: everything the game sends is a *claim* by an untrusted client.
 * Anything with account value — leaderboard rank, rewards — must be validated
 * and granted server-side. The game never sees secrets or reward rates.
 */

export interface PlayerContext {
  /** Host's user id, or null for a guest. */
  userId: string | null;
  displayName: string;
  isGuest: boolean;
}

export interface SessionInfo {
  sessionId: string;
  /** Server-issued token to bind later submissions to this session, if the host has one. */
  token?: string;
}

export interface ScoreSubmission {
  /** Unique per finished run; hosts must treat repeats as duplicates. */
  runId: string;
  /** Career score (sum of per-level bests). */
  score: number;
  level: number;
  levelScore: number;
  stars: number;
  durationMs: number;
  /** Extra facts a server can use for plausibility checks. */
  proof: { enemiesKilled: number; peakArmy: number; gateActivations: number; unitsLost: number };
}

export interface SubmissionResult {
  accepted: boolean;
  message?: string;
  rank?: number;
}

export interface LeaderboardEntry {
  rank: number;
  name: string;
  score: number;
  isPlayer?: boolean;
}

export interface RewardEligibility {
  eligible: boolean;
  /** Human-readable, decided by the host (e.g. "Top 100 this week win coins"). */
  description?: string;
}

export type AnalyticsEvent =
  | 'game_open' | 'game_start' | 'level_start' | 'gate_activated' | 'enemy_defeated' | 'boss_defeated'
  | 'level_complete' | 'level_failed' | 'upgrade_purchased' | 'game_exit';

export type AnalyticsParams = Record<string, string | number | boolean>;

export interface HashArcadeAdapter {
  readonly name: string;
  getPlayer(): Promise<PlayerContext>;
  startSession(): Promise<SessionInfo>;
  submitScore(submission: ScoreSubmission): Promise<SubmissionResult>;
  /** Null when the host shows its own leaderboard and exposes none to the game. */
  getLeaderboard(limit: number): Promise<LeaderboardEntry[] | null>;
  getRewardEligibility(): Promise<RewardEligibility>;
  /** Fire-and-forget; must never throw or block. */
  track(event: AnalyticsEvent, params?: AnalyticsParams): void;
  haptic(kind: 'light' | 'medium' | 'heavy'): void;
  /**
   * Price of a continue in the host's currency, or null if the host sells none.
   * The host sets the price; the game only displays it.
   */
  continueOffer(): Promise<ContinueOffer | null>;
  /** Ask the host to charge for a continue. Resolves true only if the player actually paid. */
  payContinue(): Promise<boolean>;
  /** Prices and balance for upgrades and skins, or null if the host sells none. */
  shopCatalog(): Promise<ShopCatalog | null>;
  /** Ask the host to charge for an item. `ok` only if the player actually paid. */
  buyItem(item: ShopItem): Promise<PurchaseResult>;
}

/** Something the player can buy with the host's currency. */
export type ShopItem =
  /** `level` is the level the upgrade is at now; buying takes it to level + 1. */
  | { kind: 'upgrade'; id: string; level: number }
  /** Army and cannon skins are owned separately, so `slot` says which one. */
  | { kind: 'skin'; slot: 'army' | 'cannon'; id: string };

/** The host's price list. The game displays these numbers and never sets them. */
export interface ShopCatalog {
  /** Display name of the currency, e.g. "HashCoins". */
  currency: string;
  /** The player's balance, or null when the host could not read it. */
  balance: number | null;
  /** Upgrade id → price of each next level (index = current level). */
  upgrades: Record<string, number[]>;
  /** Skin id → price. */
  skins: Record<string, number>;
}

export interface PurchaseResult {
  ok: boolean;
  /** Balance after the attempt, when the host knows it. */
  balance: number | null;
}

export interface ContinueOffer {
  cost: number;
  /** Display name of the currency, e.g. "HashCoins". */
  currency: string;
}

interface FlutterBridge {
  callHandler(name: string, ...args: unknown[]): Promise<unknown>;
}

function flutterBridge(): FlutterBridge | null {
  const bridge = (window as unknown as { flutter_inappwebview?: FlutterBridge }).flutter_inappwebview;
  return bridge && typeof bridge.callHandler === 'function' ? bridge : null;
}

/**
 * Adapter for the Hash app's in-app WebView. It uses only the handlers that
 * WebView registers today (lib/features/mini_games/html_games/widgets/
 * game_web_view.dart): `gameScore`, `analytics`, `haptic`, `coinContinue`,
 * `coinShop`. The app resolves
 * the signed-in user itself, so no identity or token ever enters the page.
 */
export class FlutterBridgeAdapter implements HashArcadeAdapter {
  readonly name = 'hash-app';
  constructor(private readonly bridge: FlutterBridge) {}

  async getPlayer(): Promise<PlayerContext> {
    // The app does not expose who is signed in; it attaches the user when it records the score.
    return { userId: null, displayName: 'You', isGuest: false };
  }

  async startSession(): Promise<SessionInfo> {
    return { sessionId: `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}` };
  }

  async submitScore(s: ScoreSubmission): Promise<SubmissionResult> {
    const reply = (await this.bridge.callHandler('gameScore', {
      score: s.score, runId: s.runId, level: s.level, levelScore: s.levelScore, stars: s.stars, durationMs: s.durationMs, ...s.proof,
    })) as { accepted?: boolean; message?: string } | null;
    return { accepted: reply?.accepted === true, message: reply?.message };
  }

  async getLeaderboard(): Promise<LeaderboardEntry[] | null> {
    return null;
  }

  async getRewardEligibility(): Promise<RewardEligibility> {
    return { eligible: true, description: 'Rewards are decided by Hash Arcade.' };
  }

  track(event: AnalyticsEvent, params: AnalyticsParams = {}): void {
    this.bridge.callHandler('analytics', { event: `hash_rush_${event}`, params }).catch(() => {});
  }

  haptic(kind: 'light' | 'medium' | 'heavy'): void {
    this.bridge.callHandler('haptic', kind).catch(() => {});
  }

  // The amount is fixed in the app (MiniGameCoins.hashRushContinue); the page cannot choose it.
  async continueOffer(): Promise<ContinueOffer | null> {
    const reply = (await this.bridge.callHandler('coinContinue', { quote: true })) as { cost?: unknown } | null;
    return typeof reply?.cost === 'number' && reply.cost > 0 ? { cost: reply.cost, currency: 'HashCoins' } : null;
  }

  async payContinue(): Promise<boolean> {
    const reply = (await this.bridge.callHandler('coinContinue', { quote: false })) as { ok?: boolean } | null;
    return reply?.ok === true;
  }

  // Prices live in the app (HashRushShop); the page names an item and the app decides what it costs.
  async shopCatalog(): Promise<ShopCatalog | null> {
    const reply = (await this.bridge.callHandler('coinShop', { action: 'catalog' })) as Partial<ShopCatalog> | null;
    if (!reply || typeof reply.upgrades !== 'object' || typeof reply.skins !== 'object') return null;
    return {
      currency: 'HashCoins',
      balance: typeof reply.balance === 'number' ? reply.balance : null,
      upgrades: reply.upgrades as Record<string, number[]>,
      skins: reply.skins as Record<string, number>,
    };
  }

  async buyItem(item: ShopItem): Promise<PurchaseResult> {
    const reply = (await this.bridge.callHandler('coinShop', { action: 'buy', ...item })) as { ok?: boolean; balance?: unknown } | null;
    return { ok: reply?.ok === true, balance: typeof reply?.balance === 'number' ? reply.balance : null };
  }
}

/** Pick the adapter for the environment the page finds itself in. */
export async function createAdapter(): Promise<HashArcadeAdapter> {
  const bridge = flutterBridge();
  if (bridge) return new FlutterBridgeAdapter(bridge);
  const { MockAdapter } = await import('./MockAdapter');
  return new MockAdapter();
}
