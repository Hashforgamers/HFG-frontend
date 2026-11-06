import type {
  AnalyticsEvent, AnalyticsParams, ContinueOffer, HashArcadeAdapter, LeaderboardEntry, PlayerContext, PurchaseResult, RewardEligibility,
  ScoreSubmission, SessionInfo, ShopCatalog, ShopItem, SubmissionResult,
} from './HashArcadeAdapter';
import { SKINS } from '../gameplay/Skins';
import { UPGRADES, UPGRADE_IDS, upgradeCost } from '../gameplay/Upgrades';

const NAMES = ['NovaByte', 'PixelRonin', 'Zer0Cool', 'GlitchQueen', 'TurboTanuki', 'HexHunter', 'LagSlayer', 'ByteBandit', 'RogueVolt', 'CyberMango', 'QuantumKid', 'IronLotus'];

export interface MockOptions {
  /** Simulate an unreachable backend. */
  offline?: boolean;
  latencyMs?: number;
}

/**
 * Stand-in host for local development, the standalone web build and tests.
 * Guest player, in-memory best score, a made-up leaderboard. Nothing here has
 * account value.
 */
export class MockAdapter implements HashArcadeAdapter {
  readonly name = 'mock';
  readonly events: { event: AnalyticsEvent; params: AnalyticsParams }[] = [];
  readonly submissions: ScoreSubmission[] = [];
  private best = 0;
  private readonly seen = new Set<string>();

  constructor(public options: MockOptions = {}) {}

  private async net(): Promise<void> {
    if (this.options.latencyMs) await new Promise((r) => setTimeout(r, this.options.latencyMs));
    if (this.options.offline) throw new Error('network unavailable');
  }

  async getPlayer(): Promise<PlayerContext> {
    return { userId: null, displayName: 'Guest', isGuest: true };
  }

  async startSession(): Promise<SessionInfo> {
    await this.net();
    return { sessionId: `mock-${Date.now().toString(36)}` };
  }

  async submitScore(s: ScoreSubmission): Promise<SubmissionResult> {
    await this.net();
    if (this.seen.has(s.runId)) return { accepted: false, message: 'duplicate run' };
    if (!Number.isFinite(s.score) || s.score < 0) return { accepted: false, message: 'invalid score' };
    this.seen.add(s.runId);
    this.submissions.push(s);
    this.best = Math.max(this.best, s.score);
    const board = this.board(50);
    return { accepted: true, rank: board.find((e) => e.isPlayer)?.rank };
  }

  private board(limit: number): LeaderboardEntry[] {
    const rows: LeaderboardEntry[] = NAMES.map((name, i) => ({ rank: 0, name, score: Math.round(180000 / (1 + i * 0.55)) }));
    rows.push({ rank: 0, name: 'You (guest)', score: this.best, isPlayer: true });
    rows.sort((a, b) => b.score - a.score);
    rows.forEach((row, i) => (row.rank = i + 1));
    return rows.slice(0, limit);
  }

  async getLeaderboard(limit: number): Promise<LeaderboardEntry[]> {
    await this.net();
    return this.board(limit);
  }

  async getRewardEligibility(): Promise<RewardEligibility> {
    return { eligible: false, description: 'Sign in through Hash Arcade to compete for rewards.' };
  }

  /** Pretend wallet so continues and the shop can be exercised outside the app. */
  wallet = 3000;

  async continueOffer(): Promise<ContinueOffer | null> {
    return { cost: 1000, currency: 'test coins' };
  }

  async payContinue(): Promise<boolean> {
    await this.net();
    if (this.wallet < 1000) return false;
    this.wallet -= 1000;
    return true;
  }

  /** Sample prices from the game's own tables; the real ones come from the app. */
  private prices(): Pick<ShopCatalog, 'upgrades' | 'skins'> {
    const upgrades: Record<string, number[]> = {};
    for (const id of UPGRADE_IDS) upgrades[id] = Array.from({ length: UPGRADES[id].maxLevel }, (_, level) => upgradeCost(id, level));
    const skins: Record<string, number> = {};
    for (const skin of SKINS) if (skin.price > 0) skins[skin.id] = skin.price;
    return { upgrades, skins };
  }

  async shopCatalog(): Promise<ShopCatalog | null> {
    return { currency: 'test coins', balance: this.wallet, ...this.prices() };
  }

  async buyItem(item: ShopItem): Promise<PurchaseResult> {
    await this.net();
    const { upgrades, skins } = this.prices();
    const cost = item.kind === 'upgrade' ? upgrades[item.id]?.[item.level] : skins[item.id];
    if (cost == null || this.wallet < cost) return { ok: false, balance: this.wallet };
    this.wallet -= cost;
    return { ok: true, balance: this.wallet };
  }

  /** Seed the mock with the locally saved career score. */
  setLocalBest(score: number): void {
    this.best = Math.max(this.best, score);
  }

  track(event: AnalyticsEvent, params: AnalyticsParams = {}): void {
    if (this.events.length < 500) this.events.push({ event, params });
  }

  haptic(kind: 'light' | 'medium' | 'heavy'): void {
    // browsers block vibration until the user has touched the page
    if (!(navigator as Navigator & { userActivation?: { hasBeenActive: boolean } }).userActivation?.hasBeenActive) return;
    try {
      navigator.vibrate?.(kind === 'heavy' ? 30 : kind === 'medium' ? 16 : 8);
    } catch {
      /* not supported */
    }
  }
}
