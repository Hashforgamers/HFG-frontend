import * as THREE from 'three';
import { AudioManager } from '../audio/AudioManager';
import { BOSS_STATS, BossState } from '../gameplay/BossSystem';
import { Simulation, type RunSummary, type SimInput, type SimOptions } from '../gameplay/Simulation';
import { skinById, type SkinKind } from '../gameplay/Skins';
import { ENDLESS_HEAL, ENDLESS_MAX_CARRY, ENDLESS_UNLOCK_LEVEL, endlessStage } from '../levels/Endless';
import { SkinScreen } from '../ui/SkinScreen';
import { ContinueScreen } from '../ui/ContinueScreen';
import type { ContinueOffer, ShopCatalog, ShopItem } from '../integration/HashArcadeAdapter';
import { UPGRADES, computeStats, type UpgradeId } from '../gameplay/Upgrades';
import { FX, TRACK_HALF, UNIT_CAP } from '../gameplay/constants';
import { createAdapter, type HashArcadeAdapter } from '../integration/HashArcadeAdapter';
import { WORLD_NAMES, gateLabel, type LevelConfig } from '../levels/LevelConfig';
import { LEVEL_COUNT, getLevel } from '../levels/LevelManager';
import { QualityManager, type QualityPreset } from '../optimization/QualityManager';
import { BossView } from '../rendering/BossView';
import { crowdTime } from '../rendering/BotMesh';
import { CameraController } from '../rendering/CameraController';
import { CannonView } from '../rendering/CannonView';
import { CrowdView } from '../rendering/CrowdView';
import { Effects } from '../rendering/Effects';
import { Environment } from '../rendering/Environment';
import { GateView } from '../rendering/GateView';
import { Lighting } from '../rendering/Lighting';
import { ObstacleView, TelegraphView } from '../rendering/ObstacleView';
import { Renderer } from '../rendering/Renderer';
import { HUD } from '../ui/HUD';
import { LeaderboardScreen } from '../ui/LeaderboardScreen';
import { LevelSelect } from '../ui/LevelSelect';
import { MainMenu } from '../ui/MainMenu';
import { PauseMenu } from '../ui/PauseMenu';
import { ResultsScreen } from '../ui/ResultsScreen';
import { SettingsScreen } from '../ui/SettingsScreen';
import { UpgradeScreen } from '../ui/UpgradeScreen';
import { h, type ScreenView } from '../ui/dom';
import { AssetManager } from './AssetManager';
import { GameLoop } from './GameLoop';
import { applyEndless, applyRun, careerScore, equipSkin, grantSkin, grantUpgrade, loadSave, ownsSkin, storeSave, type RunReward, type SaveData, type Screen, type Settings } from './GameState';

const BOSS_COLORS = { titan: 0xff8a3a, inferno: 0xff5a1e, void: 0xb06bff } as const;

function storage(): Storage | null {
  try {
    return window.localStorage;
  } catch {
    return null;
  }
}

/** Wires simulation, rendering, audio, UI and the host adapter together and owns the screen flow. */
export class Game {
  private readonly canvas: HTMLCanvasElement;
  private readonly ui: HTMLElement;
  private readonly assets = new AssetManager();
  private readonly audio = new AudioManager();
  private readonly loop: GameLoop;
  private readonly cameraCtl = new CameraController();
  private save: SaveData;
  private adapter!: HashArcadeAdapter;
  private quality!: QualityManager;
  private renderer!: Renderer;
  private lighting!: Lighting;
  private effects!: Effects;
  private crowdView!: CrowdView;

  // per-level
  private sim!: Simulation;
  private level!: LevelConfig;
  private env: Environment | null = null;
  private gateView: GateView | null = null;
  private obstacleView: ObstacleView | null = null;
  private telegraphView: TelegraphView | null = null;
  private bossView: BossView | null = null;
  private cannonView: CannonView | null = null;

  // ui
  private hud!: HUD;
  private menu!: MainMenu;
  private levels!: LevelSelect;
  private pauseMenu!: PauseMenu;
  private results!: ResultsScreen;
  private upgrades!: UpgradeScreen;
  private settings!: SettingsScreen;
  private board!: LeaderboardScreen;
  private screens!: Record<Exclude<Screen, 'loading' | 'playing'>, ScreenView>;
  private debugEl: HTMLElement | null = null;

  screen: Screen = 'loading';
  /** Where "back" from upgrades/settings/leaderboard returns to. */
  private returnTo: Screen = 'menu';
  private readonly input: SimInput = { aimX: 0, ability: false };
  private readonly keys = new Set<string>();
  private dragId = -1;
  private dragStartX = 0;
  private dragStartAim = 0;
  private time = 0;
  private endTimer = 0;
  private lastSummary: RunSummary | null = null;
  private lastReward: RunReward | null = null;
  private submitNote = '';
  private runSeq = 0;
  private sessionId = 'local';
  private killsReported = 0;
  private analyticsT = 0;
  private bossFxT = 0;
  private hinted = false;
  private slowTick = 0;
  private mode: 'campaign' | 'endless' = 'campaign';
  /** Totals of the endless run in progress (finished stages only). */
  private run = { stage: 0, score: 0, kills: 0, lost: 0, time: 0, peak: 0, gates: 0 };
  private skinScreen!: SkinScreen;
  private continueScreen!: ContinueScreen;
  private continueOffer: ContinueOffer | null = null;
  private paying = false;
  /** The host's price list and the player's balance; null until it answers, or if it sells nothing. */
  private shop: ShopCatalog | null = null;
  private buying = false;
  private fade!: HTMLElement;
  private readonly gatesSeen = new Set<number>();
  private readonly v = new THREE.Vector3();
  private lastStats = { drawCalls: 0, triangles: 0, geometries: 0, textures: 0, pixelRatio: 1, width: 1, height: 1 };

  constructor(private readonly stage: HTMLElement, private readonly onLoadProgress: (fraction: number, label: string) => void) {
    this.canvas = h('canvas.game-canvas');
    this.ui = h('div.ui');
    stage.append(this.canvas, this.ui);
    this.save = loadSave(storage());
    this.loop = new GameLoop((dt) => this.step(dt), (dt) => this.render(dt));
  }

  // --- boot ------------------------------------------------------------------

  async init(): Promise<void> {
    if (!Renderer.supported()) throw new Error('WebGL2 is not available on this device/browser.');
    this.onLoadProgress(0.05, 'Connecting');
    this.adapter = await createAdapter();
    // the Hash app draws its own back button over the top-left corner
    this.stage.classList.toggle('in-app', this.adapter.name === 'hash-app');
    this.fade = h('div.fade');
    this.stage.append(this.fade);
    this.quality = new QualityManager(this.save.settings.quality, (preset, presetChanged) => this.onQuality(preset, presetChanged));
    this.renderer = new Renderer(this.canvas, this.quality.preset.antialias);
    this.lighting = new Lighting(this.renderer.scene);
    this.renderer.setBloom(this.quality.preset.bloom);

    await this.assets.load(import.meta.env.BASE_URL, (f) => this.onLoadProgress(0.1 + f * 0.8, 'Loading models'));
    this.onLoadProgress(0.95, 'Building world');
    this.buildPersistentViews();
    this.buildUi();
    this.bindInput();
    new ResizeObserver(() => this.resize()).observe(this.stage);
    this.resize();

    this.audio.setMusic(this.save.settings.music);
    this.audio.setSfx(this.save.settings.sfx);
    this.adapter.track('game_open', { adapter: this.adapter.name, quality: this.quality.level });
    void this.adapter.startSession().then((s) => (this.sessionId = s.sessionId)).catch(() => {});
    void this.flushPending();
    void this.adapter.continueOffer().then((offer) => (this.continueOffer = offer)).catch(() => {});
    void this.loadShop();

    this.loadLevel(getLevel(this.save.unlocked), true);
    this.go('menu');
    this.loop.start();
    this.onLoadProgress(1, 'Ready');
  }

  private buildPersistentViews(): void {
    const preset = this.quality.preset;
    this.effects?.group.removeFromParent();
    this.crowdView?.group.removeFromParent();
    this.crowdView?.dispose();
    this.effects = new Effects(preset.particles);
    this.crowdView = new CrowdView(this.assets, preset, skinById(this.save.skins.army));
    this.renderer.scene.add(this.crowdView.group, this.effects.group);
  }

  private onQuality(preset: QualityPreset, presetChanged: boolean): void {
    if (!this.renderer) return;
    if (presetChanged) {
      this.buildPersistentViews();
      this.buildLevelViews();
    }
    this.resize();
    this.renderer.setBloom(preset.bloom);
  }

  private resize(): void {
    const rect = this.stage.getBoundingClientRect();
    if (rect.width < 2 || rect.height < 2) return;
    this.renderer.resize(rect.width, rect.height, this.quality.pixelRatio(window.devicePixelRatio || 1));
    this.cameraCtl.setAspect(rect.width / rect.height);
  }

  // --- levels ----------------------------------------------------------------

  /** Build a level's simulation and views. `attract` = menu backdrop (not played). */
  private loadLevel(level: LevelConfig, attract: boolean, opts: SimOptions = {}): void {
    this.level = level;
    const stats = computeStats(this.save.upgrades);
    // the menu backdrop always shows a small squad, whatever the upgrades are
    this.sim = new Simulation(this.level, attract ? { ...stats, startArmy: Math.max(10, stats.startArmy) } : stats, opts);
    this.input.aimX = 0;
    this.input.ability = false;
    this.effects.clear();
    this.gatesSeen.clear();
    this.killsReported = 0;
    this.buildLevelViews();
    this.cameraCtl.reset();
    this.hud.reset();
  }

  private buildLevelViews(): void {
    if (!this.sim) return;
    const scene = this.renderer.scene;
    this.env?.dispose();
    this.gateView?.dispose();
    this.obstacleView?.dispose();
    this.telegraphView?.dispose();
    this.bossView?.dispose();
    this.cannonView?.dispose();
    this.env = new Environment(this.level, this.quality.preset);
    this.lighting.apply(this.env.theme);
    this.gateView = new GateView(this.sim.gates.gates);
    this.obstacleView = new ObstacleView(this.sim.obstacles.list, this.assets, this.env.theme.track);
    this.telegraphView = new TelegraphView(this.sim.boss.telegraphs);
    this.bossView = new BossView(this.sim.boss, this.assets);
    this.cannonView = new CannonView(this.sim.cannon, this.assets, skinById(this.save.skins.cannon));
    scene.add(this.env.group, this.gateView.group, this.obstacleView.group, this.telegraphView.group, this.bossView.group, this.cannonView.group);
  }

  startLevel(n: number): void {
    this.mode = 'campaign';
    const level = getLevel(Math.min(n, this.save.unlocked));
    this.begin(level, {}, `LEVEL ${level.id}`, WORLD_NAMES[level.world]);
    if (level.id === 1 && !this.hinted) {
      this.hud.showHint(true);
      window.setTimeout(() => this.hud.showHint(false), 6000);
    }
    this.adapter.track('game_start', { level: level.id });
    this.adapter.track('level_start', { level: level.id, world: level.world, boss: level.boss.kind });
  }

  /** Endless: generated stages back to back until the cannon dies. Cannon health and survivors carry over. */
  startEndless(): void {
    if (this.save.unlocked <= ENDLESS_UNLOCK_LEVEL) return;
    this.mode = 'endless';
    this.run = { stage: 0, score: 0, kills: 0, lost: 0, time: 0, peak: 0, gates: 0 };
    this.adapter.track('game_start', { mode: 'endless' });
    this.startStage(1, {});
  }

  private startStage(stage: number, opts: SimOptions): void {
    this.run.stage = stage;
    const level = endlessStage(stage);
    this.begin(level, opts, `STAGE ${stage}`, `Endless · ${WORLD_NAMES[level.world]}`);
    this.adapter.track('level_start', { mode: 'endless', stage, world: level.world, boss: level.boss.kind });
  }

  private begin(level: LevelConfig, opts: SimOptions, label: string, kicker: string): void {
    this.audio.unlock();
    this.loadLevel(level, false, opts);
    this.lastSummary = null;
    this.endTimer = 0;
    this.runSeq++;
    this.audio.startMusic(this.level.world);
    this.fade.classList.remove('go');
    void this.fade.offsetWidth;
    this.fade.classList.add('go');
    this.audio.setIntensity(0);
    this.go('playing');
    this.loop.reset();
    this.hud.intro(label, this.mode === 'endless' ? `Boss every stage · cannon health carries over` : level.name, level.world, kicker, BOSS_STATS[level.boss.kind].name);
  }

  private get title(): string {
    return this.mode === 'endless' ? `ENDLESS · STAGE ${this.run.stage}` : `LEVEL ${this.level.id} · ${this.level.name}`;
  }

  private replay(): void {
    if (this.mode === 'endless') this.startEndless();
    else this.startLevel(this.level.id);
  }

  // --- screens ---------------------------------------------------------------

  private buildUi(): void {
    this.hud = new HUD(() => this.pause(), () => (this.input.ability = true));
    this.menu = new MainMenu({
      play: () => this.startLevel(this.save.unlocked),
      endless: () => this.startEndless(),
      skins: () => this.open('skins'),
      levels: () => this.go('levels'),
      upgrades: () => this.open('upgrades'),
      leaderboard: () => this.open('leaderboard'),
      settings: () => this.open('settings'),
    });
    this.levels = new LevelSelect((n) => this.startLevel(n), () => this.go('menu'));
    this.pauseMenu = new PauseMenu({
      resume: () => this.resume(),
      restart: () => this.replay(),
      settings: () => this.open('settings'),
      quit: () => this.quitToMenu(),
    });
    this.results = new ResultsScreen({
      next: () => this.startLevel(Math.min(LEVEL_COUNT, this.level.id + 1)),
      retry: () => this.replay(),
      upgrades: () => this.open('upgrades'),
      menu: () => this.quitToMenu(),
    });
    this.upgrades = new UpgradeScreen((id) => void this.buy(id), () => this.go(this.returnTo));
    this.settings = new SettingsScreen((s) => this.applySettings(s), () => this.go(this.returnTo), () => this.infoLine());
    this.board = new LeaderboardScreen(() => this.go(this.returnTo));
    this.continueScreen = new ContinueScreen({ pay: () => void this.payContinue(), decline: () => this.declineContinue() });
    this.skinScreen = new SkinScreen((kind, id) => void this.pickSkin(kind, id), () => this.go(this.returnTo));
    this.screens = {
      menu: this.menu, levels: this.levels, paused: this.pauseMenu, won: this.results, lost: this.results,
      upgrades: this.upgrades, settings: this.settings, leaderboard: this.board, skins: this.skinScreen, continue: this.continueScreen,
    };
    this.ui.append(this.hud.el, this.menu.el, this.levels.el, this.pauseMenu.el, this.results.el, this.upgrades.el, this.settings.el, this.board.el, this.skinScreen.el, this.continueScreen.el);
    if (new URLSearchParams(location.search).has('debug')) {
      this.debugEl = h('pre.debug');
      this.ui.append(this.debugEl);
    }
    // every button gets a click sound and unlocks audio
    this.ui.addEventListener('click', (e) => {
      if ((e.target as HTMLElement).closest('button')) {
        this.audio.unlock();
        this.audio.play('click');
      }
    });
  }

  /** Open a sub-screen and remember where to come back to. */
  private open(screen: 'upgrades' | 'settings' | 'leaderboard' | 'skins'): void {
    this.returnTo = this.screen === 'settings' || this.screen === 'upgrades' || this.screen === 'leaderboard' || this.screen === 'skins' ? this.returnTo : this.screen;
    this.go(screen);
  }

  private go(screen: Screen): void {
    this.screen = screen;
    for (const key of Object.keys(this.screens) as (keyof typeof this.screens)[]) this.screens[key].el.classList.remove('show');
    if (screen !== 'playing' && screen !== 'loading') this.screens[screen].el.classList.add('show');
    this.hud.show(screen === 'playing' || screen === 'paused' || screen === 'continue');
    switch (screen) {
      case 'menu': this.menu.refresh(this.save, this.shop); break;
      case 'levels': this.levels.refresh(this.save); break;
      case 'paused':
        this.pauseMenu.refresh({ title: this.title, progress: this.sim.progress, army: this.sim.crowd.count, score: (this.mode === 'endless' ? this.run.score : 0) + this.sim.score() });
        break;
      case 'upgrades': this.upgrades.refresh(this.save, this.shop); void this.loadShop(); break;
      case 'skins': this.skinScreen.refresh(this.save, this.shop); void this.loadShop(); break;
      case 'settings': this.settings.refresh(this.save.settings); break;
      case 'leaderboard': void this.showLeaderboard(); break;
      case 'won': case 'lost':
        if (this.lastSummary && this.lastReward) this.results.show(this.lastSummary, this.lastReward, this.mode === 'campaign' && this.level.id < LEVEL_COUNT, this.submitNote, this.sim.progress, this.mode === 'endless' ? this.run.stage : 0);
        break;
    }
  }

  private pause(): void {
    if (this.screen !== 'playing' || this.sim.status !== 'playing') return;
    this.go('paused');
    this.audio.suspend();
  }

  private resume(): void {
    if (this.screen !== 'paused') return;
    this.audio.resume();
    this.go('playing');
    this.loop.reset();
  }

  private quitToMenu(): void {
    this.audio.resume();
    this.audio.stopMusic();
    if (this.sim.status === 'playing' && (this.screen === 'paused' || this.screen === 'playing')) {
      this.adapter.track('game_exit', { level: this.level.id, progress: Number(this.sim.progress.toFixed(2)) });
    }
    // leaving an endless run banks the stages already cleared
    if (this.mode === 'endless' && this.sim.status === 'playing' && this.run.score > 0) {
      applyEndless(this.save, this.run.score, this.run.stage - 1);
      this.persist();
    }
    this.mode = 'campaign';
    this.loadLevel(getLevel(this.save.unlocked), true);
    this.go('menu');
  }

  /** Fetch the host's prices and the player's balance, then redraw whichever screen shows them. */
  private async loadShop(): Promise<void> {
    try {
      this.shop = await this.adapter.shopCatalog();
    } catch {
      return; // keep the last known prices
    }
    this.refreshShopViews();
  }

  private refreshShopViews(): void {
    if (this.screen === 'upgrades') this.upgrades.refresh(this.save, this.shop);
    else if (this.screen === 'skins') this.skinScreen.refresh(this.save, this.shop);
    else if (this.screen === 'menu') this.menu.refresh(this.save, this.shop);
  }

  /** Ask the host to charge for an item. The save only changes once it says the player paid. */
  private async purchase(item: ShopItem): Promise<boolean> {
    if (this.buying) return false;
    this.buying = true;
    try {
      const result = await this.adapter.buyItem(item);
      if (this.shop && result.balance != null) this.shop.balance = result.balance;
      return result.ok;
    } catch {
      return false;
    } finally {
      this.buying = false;
    }
  }

  private async pickSkin(kind: SkinKind, id: string): Promise<void> {
    let sound: 'click' | 'buy' | 'deny' = 'click';
    if (!equipSkin(this.save, kind, id)) {
      if (await this.purchase({ kind: 'skin', slot: kind, id })) {
        grantSkin(this.save, kind, id);
        sound = 'buy';
      } else {
        sound = 'deny';
      }
    }
    this.audio.play(sound);
    if (ownsSkin(this.save, kind, id)) {
      this.persist();
      // rebuild the models so the change shows immediately behind the sheet
      this.buildPersistentViews();
      this.buildLevelViews();
    }
    this.refreshShopViews();
  }

  private async buy(id: UpgradeId): Promise<void> {
    const level = this.save.upgrades[id];
    if (level < UPGRADES[id].maxLevel && (await this.purchase({ kind: 'upgrade', id, level })) && grantUpgrade(this.save, id)) {
      this.audio.play('buy');
      this.adapter.track('upgrade_purchased', { upgrade: id, level: this.save.upgrades[id] });
      this.persist();
    } else {
      this.audio.play('deny');
    }
    this.refreshShopViews();
  }

  private applySettings(settings: Settings): void {
    this.save.settings = settings;
    this.audio.unlock();
    this.audio.setMusic(settings.music);
    this.audio.setSfx(settings.sfx);
    this.quality.set(settings.quality);
    this.persist();
  }

  private persist(): void {
    storeSave(storage(), this.save);
  }

  private infoLine(): string {
    const s = this.lastStats;
    return `Quality: ${this.quality.level} · ${s.width}×${s.height} @${s.pixelRatio.toFixed(2)}x · host: ${this.adapter.name}`;
  }

  private async showLeaderboard(): Promise<void> {
    this.board.loading();
    const career = careerScore(this.save);
    try {
      const mock = this.adapter as HashArcadeAdapter & { setLocalBest?(score: number): void };
      mock.setLocalBest?.(career);
      const [entries, reward] = await Promise.all([this.adapter.getLeaderboard(20), this.adapter.getRewardEligibility()]);
      if (this.screen !== 'leaderboard') return;
      if (entries) this.board.show(entries, career, `${this.adapter.name === 'mock' ? 'Sample data (offline mock). ' : ''}${reward.description ?? ''}`);
      else this.board.show(null, career, 'Live rankings are shown in Hash Arcade’s leaderboard. Your career score is submitted after every win.');
    } catch {
      if (this.screen === 'leaderboard') this.board.show(null, career, 'Could not reach the leaderboard. Check your connection and try again.', true);
    }
  }

  // --- input -----------------------------------------------------------------

  private bindInput(): void {
    const stage = this.stage;
    const down = (e: PointerEvent) => {
      this.audio.unlock();
      if (this.screen !== 'playing' || (e.target as HTMLElement).closest('button')) return;
      this.dragId = e.pointerId;
      this.dragStartX = e.clientX;
      this.dragStartAim = this.input.aimX;
      if (!this.hinted) {
        this.hinted = true;
        this.hud.showHint(false);
      }
    };
    const move = (e: PointerEvent) => {
      if (this.screen !== 'playing') return;
      const rect = stage.getBoundingClientRect();
      if (e.pointerId === this.dragId) {
        // relative drag: a swipe across ~60% of the screen covers the whole track
        const dx = (e.clientX - this.dragStartX) / rect.width;
        this.input.aimX = Math.max(-TRACK_HALF, Math.min(TRACK_HALF, this.dragStartAim + dx * TRACK_HALF * 3.4));
      } else if (e.pointerType === 'mouse' && this.dragId < 0 && e.buttons === 0) {
        // desktop: the cannon follows the cursor
        this.input.aimX = ((e.clientX - rect.left) / rect.width - 0.5) * TRACK_HALF * 2.5;
      }
    };
    const up = (e: PointerEvent) => {
      // pointercancel (system gesture, incoming call) ends the drag exactly like a lift
      if (e.pointerId === this.dragId) this.dragId = -1;
    };
    stage.addEventListener('pointerdown', down);
    window.addEventListener('pointermove', move);
    window.addEventListener('pointerup', up);
    window.addEventListener('pointercancel', up);
    stage.addEventListener('contextmenu', (e) => e.preventDefault());

    window.addEventListener('keydown', (e) => {
      if (e.repeat) return;
      this.keys.add(e.code);
      if (e.code === 'Escape' || e.code === 'KeyP') {
        if (this.screen === 'playing') this.pause();
        else if (this.screen === 'paused') this.resume();
      }
      if ((e.code === 'Space' || e.code === 'KeyE') && this.screen === 'playing') {
        this.input.ability = true;
        e.preventDefault();
      }
      if ((e.code === 'Enter' || e.code === 'Space') && this.screen === 'menu') this.startLevel(this.save.unlocked);
    });
    window.addEventListener('keyup', (e) => this.keys.delete(e.code));
    window.addEventListener('blur', () => {
      this.keys.clear();
      this.dragId = -1;
    });
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        // tab switched / app backgrounded: freeze the run and the audio clock
        if (this.screen === 'playing') this.pause();
        this.audio.suspend();
        this.loop.stop();
      } else {
        if (this.screen !== 'paused') this.audio.resume();
        this.loop.start();
      }
    });
    window.addEventListener('pagehide', () => {
      if (this.screen === 'playing' || this.screen === 'paused') this.adapter.track('game_exit', { level: this.level.id });
    });
  }

  // --- simulation ---------------------------------------------------------------

  private step(dt: number): void {
    if (this.screen !== 'playing') return;
    const left = this.keys.has('ArrowLeft') || this.keys.has('KeyA');
    const right = this.keys.has('ArrowRight') || this.keys.has('KeyD');
    if (left !== right) {
      this.input.aimX = Math.max(-TRACK_HALF, Math.min(TRACK_HALF, this.input.aimX + (right ? 1 : -1) * 11 * dt));
      if (!this.hinted) {
        this.hinted = true;
        this.hud.showHint(false);
      }
    }
    if (this.sim.status === 'playing') {
      // the killing blow plays out in slow motion
      if (this.sim.boss.state === BossState.Dying && ++this.slowTick % 3 !== 0) return;
      this.sim.step(this.input, dt);
      this.input.ability = false;
      this.presentFx();
      this.sim.fx.clear();
      const status: string = this.sim.status; // re-read: the step may have ended the run
      if (status === 'lost' && this.continueOffer && this.sim.continues === 0) {
        // one paid continue per run, offered before the run is closed out
        this.audio.play('defeat');
        this.audio.setIntensity(0);
        this.continueScreen.show(this.continueOffer);
        this.go('continue');
      } else if (status !== 'playing') {
        this.finish();
      }
    } else if (this.endTimer > 0) {
      this.endTimer -= dt;
      if (this.endTimer > 0) return;
      if (this.mode === 'endless' && this.sim.status === 'won') {
        this.startStage(this.run.stage + 1, {
          startHp: this.sim.cannon.hp + ENDLESS_HEAL,
          extraArmy: Math.min(ENDLESS_MAX_CARRY, this.sim.crowd.count),
        });
      } else {
        this.go(this.sim.status === 'won' ? 'won' : 'lost');
      }
    }
  }

  private async payContinue(): Promise<void> {
    if (this.paying || this.screen !== 'continue') return;
    this.paying = true;
    this.continueScreen.busy();
    let paid = false;
    try {
      paid = await this.adapter.payContinue();
    } catch {
      paid = false;
    }
    this.paying = false;
    if (this.screen !== 'continue') return;
    if (!paid) {
      this.continueScreen.failed();
      return;
    }
    this.sim.revive();
    this.presentFx();
    this.sim.fx.clear();
    this.adapter.track('game_start', { level: this.level.id, continued: true });
    this.hud.announce('BACK IN THE FIGHT', 'good', 1500);
    this.go('playing');
    this.loop.reset();
  }

  private declineContinue(): void {
    if (this.paying || this.screen !== 'continue') return;
    this.continueScreen.stop();
    this.finish();
    this.endTimer = 0;
    this.go('lost');
  }

  /** An endless stage ended: bank it and roll on, or close out the run. */
  private finishStage(stage: RunSummary): void {
    const r = this.run;
    const won = stage.status === 'won';
    r.score += stage.score;
    r.kills += stage.enemiesKilled;
    r.lost += stage.unitsLost;
    r.time += stage.time;
    r.gates += stage.gateActivations;
    r.peak = Math.max(r.peak, stage.peakArmy);
    this.audio.setIntensity(0);
    this.audio.stopMusic();
    this.audio.play(won ? 'victory' : 'defeat');
    this.haptic(won ? 'medium' : 'heavy');
    this.reportKills();
    this.adapter.track(won ? 'level_complete' : 'level_failed', { mode: 'endless', stage: r.stage, score: r.score });
    if (won) {
      this.endTimer = 2.2;
      return;
    }
    const total: RunSummary = {
      levelId: 0, status: 'lost', score: r.score, time: r.time, enemiesKilled: r.kills, unitsLost: r.lost,
      peakArmy: r.peak, armyLeft: 0, gateActivations: r.gates, cannonHp: 0, stars: 0,
    };
    this.lastSummary = total;
    this.lastReward = { newBest: applyEndless(this.save, r.score, r.stage), unlockedLevel: null };
    this.submitNote = '';
    this.persist();
    this.endTimer = 1.3;
    void this.submit(total);
  }

  private finish(): void {
    const run = this.sim.summary();
    if (this.mode === 'endless') {
      this.finishStage(run);
      return;
    }
    const won = run.status === 'won';
    this.lastSummary = run;
    this.lastReward = applyRun(this.save, this.level, run);
    this.submitNote = '';
    this.persist();
    this.endTimer = won ? 2.4 : 1.3;
    this.audio.setIntensity(0);
    this.audio.stopMusic();
    this.audio.play(won ? 'victory' : 'defeat');
    this.haptic(won ? 'medium' : 'heavy');
    this.reportKills();
    const params = { level: this.level.id, score: run.score, time: Math.round(run.time), peak_army: run.peakArmy, units_lost: run.unitsLost };
    this.adapter.track(won ? 'level_complete' : 'level_failed', won ? { ...params, stars: run.stars } : { ...params, progress: Number(this.sim.progress.toFixed(2)) });
    if (won) void this.submit(run);
  }

  /** Send the career score to the host. A failure is queued and retried on the next launch. */
  private async submit(run: RunSummary): Promise<void> {
    const submission = {
      runId: `${this.sessionId}-${this.runSeq}-${Date.now().toString(36)}`,
      score: careerScore(this.save),
      level: run.levelId,
      levelScore: run.score,
      stars: run.stars,
      durationMs: Math.round(run.time * 1000),
      proof: { enemiesKilled: run.enemiesKilled, peakArmy: run.peakArmy, gateActivations: run.gateActivations, unitsLost: run.unitsLost },
    };
    try {
      const result = await this.adapter.submitScore(submission);
      if (!result.accepted && result.message) this.submitNote = result.message;
    } catch {
      this.save.pending.push({ runId: submission.runId, score: submission.score, level: submission.level });
      this.save.pending = this.save.pending.slice(-10);
      this.persist();
      this.submitNote = 'Offline — your score is saved and will be sent next time.';
    }
    if ((this.screen === 'won' || this.screen === 'lost') && this.lastSummary && this.lastReward) {
      this.results.show(this.lastSummary, this.lastReward, this.mode === 'campaign' && this.level.id < LEVEL_COUNT, this.submitNote, this.sim.progress, this.mode === 'endless' ? this.run.stage : 0);
    }
  }

  private async flushPending(): Promise<void> {
    const queue = this.save.pending;
    if (queue.length === 0) return;
    // only the most recent career score matters
    const last = queue[queue.length - 1]!;
    try {
      await this.adapter.submitScore({
        runId: last.runId, score: Math.max(last.score, careerScore(this.save)), level: last.level, levelScore: 0, stars: 0, durationMs: 0,
        proof: { enemiesKilled: 0, peakArmy: 0, gateActivations: 0, unitsLost: 0 },
      });
      this.save.pending = [];
      this.persist();
    } catch {
      /* still offline: keep the queue */
    }
  }

  private reportKills(): void {
    const killed = this.sim.enemies.killed - this.killsReported;
    if (killed > 0) this.adapter.track('enemy_defeated', { level: this.level.id, count: killed });
    this.killsReported = this.sim.enemies.killed;
  }

  private haptic(kind: 'light' | 'medium' | 'heavy'): void {
    if (this.save.settings.haptics) this.adapter.haptic(kind);
  }

  // --- presentation of simulation events -----------------------------------------

  private toScreen(x: number, y: number, z: number): { x: number; y: number } {
    const rect = this.stage.getBoundingClientRect();
    this.v.set(x, y, -z).project(this.cameraCtl.camera);
    return { x: (this.v.x * 0.5 + 0.5) * rect.width, y: (-this.v.y * 0.5 + 0.5) * rect.height };
  }

  private presentFx(): void {
    const fx = this.sim.fx;
    const e = this.effects;
    const a = this.audio;
    const low = this.quality.level === 'low';
    const k = low ? 0.5 : 1;
    for (let i = 0; i < fx.n; i++) {
      const x = fx.x[i]!;
      const z = -fx.z[i]!;
      const arg = fx.a[i]!;
      switch (fx.type[i]) {
        case FX.Muzzle:
          a.play('shoot', this.sim.cannon.overdrive > 0 ? 1.25 : 1);
          e.burst(x, 1.25, z, 3 * k, 0x9fefff, 3, 0.18, 0.22, 0, 0.3);
          break;
        case FX.PodLand:
          a.play('deploy');
          e.ring(x, z, 0x4fd8ff, 0.9, 0.3);
          e.burst(x, 0.3, z, 4 * k, 0x6fdcff, 2.5, 0.3, 0.16, 4);
          break;
        case FX.PodHit:
          a.play('hit');
          e.burst(x, 1, z, 8 * k, 0xbff4ff, 6, 0.3, 0.2, 6);
          break;
        case FX.UnitDie:
          a.play('unitDie');
          e.burst(x, 0.6, z, (arg ? 7 : 3) * k, 0x2f7bff, 4.5, 0.5, 0.14, 12, 0.9, true);
          break;
        case FX.UnitFall:
          a.play('unitDie', 0.6);
          break;
        case FX.EnemyHit:
          a.play('hit', 0.8);
          e.burst(x, 0.8, z, 2 * k, 0xffb07a, 4, 0.22, 0.14, 8);
          break;
        case FX.EnemyDie: {
          a.play('enemyDie', arg === 2 ? 0.5 : arg === 1 ? 0.75 : 1);
          const big = arg === 2;
          e.burst(x, 0.7, z, (big ? 30 : 9) * k, 0xe0241e, big ? 10 : 6.5, 0.7, big ? 0.3 : 0.19, 13, 1.2, true);
          e.burst(x, 0.8, z, (big ? 14 : 4) * k, 0xffa33a, 5, 0.35, 0.3, 2);
          if (big || arg === 3) {
            e.ring(x, z, 0xff6a2a, 3.2, 0.5);
            this.cameraCtl.shake(0.35);
          }
          break;
        }
        case FX.GateAdd: case FX.GateMul: {
          const mul = fx.type[i] === FX.GateMul;
          a.play(arg >= 40 ? 'gateBig' : 'gate', mul ? 1.15 : 1);
          e.burst(x, 1.4, z, Math.min(26, 6 + arg / 4) * k, mul ? 0x9d7bff : 0x5dffb0, 6, 0.55, 0.2, 5, 1);
          e.ring(x, z, mul ? 0x9d7bff : 0x5dffb0, 2.4, 0.4);
          const p = this.toScreen(x, 3.6, -z);
          this.hud.float(`+${Math.round(arg)}`, p.x, p.y, mul ? '#c4b0ff' : '#8dffc8', arg >= 40);
          if (arg >= 40) this.haptic('light');
          break;
        }
        case FX.GateLoss: {
          a.play('deny');
          a.play('unitDie', 0.7);
          e.ring(x, z, 0xff3b3b, 2.6, 0.4);
          const p = this.toScreen(x, 3.6, -z);
          this.hud.float(`−${Math.round(arg)}`, p.x, p.y, '#ff6b6b', arg >= 20);
          if (arg >= 20) this.haptic('medium');
          break;
        }
        case FX.GateCapped: {
          const p = this.toScreen(x, 4.4, -z);
          this.hud.float('ARMY MAX', p.x, p.y, '#ffd23a', true);
          break;
        }
        case FX.Explosion:
          a.play('explosion');
          e.burst(x, 0.8, z, 40 * k, 0xff8a2a, 11, 0.7, 0.36, 6, 1);
          e.burst(x, 0.8, z, 16 * k, 0x3a3030, 7, 0.9, 0.24, 12, 1, true);
          e.ring(x, z, 0xffb04a, Math.max(2, arg), 0.5);
          this.cameraCtl.shake(0.55);
          this.haptic('medium');
          break;
        case FX.BossHit:
          e.burst(x, 2.5, z, 5 * k, 0xfff0b0, 6, 0.3, 0.2, 6);
          break;
        case FX.BossAttack:
          a.play('bossAttack');
          a.play('warning');
          break;
        case FX.BossIntro:
          a.play('bossRoar');
          a.setIntensity(1);
          this.hud.bossWarning(BOSS_STATS[this.level.boss.kind].name);
          this.cameraCtl.shake(0.5);
          this.haptic('heavy');
          break;
        case FX.BossDie:
          a.play('bossDie');
          this.cameraCtl.shake(1);
          this.haptic('heavy');
          this.adapter.track('boss_defeated', { level: this.level.id, boss: this.level.boss.kind, time: Math.round(this.sim.time) });
          break;
        case FX.CannonHit:
          a.play('cannonHit');
          this.cameraCtl.shake(0.4);
          this.hud.damageFlash();
          this.haptic('medium');
          e.burst(x, 1, z, 10 * k, 0xff5a3a, 6, 0.4, 0.22, 8);
          break;
        case FX.Impact:
          a.play('explosion', 1.6);
          e.burst(x, 0.3, z, 12 * k, 0xffc27a, 6, 0.4, 0.22, 9);
          e.ring(x, z, 0xff7a3a, 1.8, 0.35);
          this.cameraCtl.shake(0.2);
          break;
        case FX.Collapse:
          a.play('explosion', 0.7);
          e.burst(x, 0.2, z, 24 * k, 0x555a66, 6, 0.9, 0.3, 14, 0.8, true);
          this.cameraCtl.shake(0.3);
          break;
        case FX.TurretShot:
          a.play('shoot', 0.55);
          e.burst(x, 1.2, z, 4 * k, 0xff6a4a, 3, 0.2, 0.2, 0);
          break;
        case FX.Ability:
          a.play('ability');
          this.hud.announce('OVERDRIVE!', 'good', 1200);
          e.ring(x, z, 0xffd23a, 4, 0.5);
          this.haptic('light');
          break;
        case FX.BossShield:
          e.ring(x, z, 0xb06bff, 6, 0.6, 1.5);
          if (arg === 0) e.burst(x, 4, z, 30 * k, 0xc79bff, 9, 0.6, 0.3, 4);
          else this.hud.announce('SHIELD UP — BREAK IT', 'danger', 1500);
          break;
        case FX.Summon:
          e.ring(x, z, 0xff3a3a, 5, 0.6);
          break;
        case FX.Victory:
          e.confetti(x, 3, z - 6, low ? 60 : 160);
          break;
      }
    }
    // analytics, batched: never per kill or per frame
    for (const gate of this.sim.gates.gates) {
      if (gate.activations > 0 && !this.gatesSeen.has(gate.def.z * 100 + gate.def.x)) {
        this.gatesSeen.add(gate.def.z * 100 + gate.def.x);
        this.adapter.track('gate_activated', { level: this.level.id, gate: gateLabel(gate.def.op) });
      }
    }
    this.analyticsT += 1;
    if (this.analyticsT >= 300) {
      this.analyticsT = 0;
      this.reportKills();
    }
  }

  // --- frame ---------------------------------------------------------------------

  private render(dt: number): void {
    const frozen = this.screen === 'paused';
    if (!frozen) {
      this.time += dt;
      crowdTime.value = this.time;
    }
    const sim = this.sim;
    const attract = this.screen !== 'playing' && this.screen !== 'paused' && this.screen !== 'won' && this.screen !== 'lost' && this.screen !== 'continue';
    this.cameraCtl.lookDrop = this.screen === 'skins' ? 3.4 : 0;
    this.cameraCtl.update(frozen ? 0 : dt, sim, this.time, attract);
    const camera = this.cameraCtl.camera;

    this.crowdView.update(sim);
    this.cannonView!.update(this.time, frozen ? 0 : dt, camera);
    this.gateView!.update(this.time, attract ? -999 : sim.cannon.z);
    this.obstacleView!.update(this.time);
    this.telegraphView!.update();
    this.bossView!.update(this.time);
    this.env!.update(this.time, dt, camera.position);
    if (!frozen) {
      this.ambientFx(dt);
      this.effects.update(dt);
    }
    this.renderer.render(camera);

    if (this.screen === 'playing' || this.screen === 'paused') this.updateHud();
    if (this.screen === 'playing') this.quality.sample(dt * 1000);
    this.lastStats = this.renderer.stats();
    if (this.debugEl) this.updateDebug();
  }

  /** Continuous effects that are not tied to a single simulation event. */
  private ambientFx(dt: number): void {
    const sim = this.sim;
    const e = this.effects;
    if (this.quality.level !== 'low') {
      for (let i = 0; i < sim.pods.cap; i++) {
        if (sim.pods.live[i]) e.puff(sim.pods.x[i]!, 1.3, -sim.pods.z[i]!, 0x7fe4ff, 0.22, 0.25, 0.2);
      }
    }
    const boss = sim.boss;
    this.bossFxT -= dt;
    if (this.bossFxT > 0) return;
    this.bossFxT = 0.12;
    const bx = boss.x;
    const bz = -boss.z;
    const color = BOSS_COLORS[boss.kind];
    if (boss.state === BossState.Dying) {
      e.burst(bx + (Math.random() - 0.5) * 4, 1 + Math.random() * 5, bz + (Math.random() - 0.5) * 3, 18, 0xffa33a, 9, 0.6, 0.34, 6);
      e.burst(bx, 3, bz, 6, 0x33343c, 8, 0.9, 0.26, 12, 1, true);
      this.cameraCtl.shake(0.25);
    } else if (boss.state === BossState.Fight || boss.state === BossState.Intro) {
      if (boss.kind === 'inferno') for (let k = 0; k < 3; k++) e.puff(bx + (Math.random() - 0.5) * 3, 5.6, bz - 0.6, 0xff8a2a, 0.5, 0.9, 3);
      else if (boss.kind === 'void') e.puff(bx + (Math.random() - 0.5) * 4, 2 + Math.random() * 5, bz, color, 0.3, 0.7, 1);
      else if (boss.attackT > 1.1 && boss.attackT < 1.3) e.burst(bx, 0.3, bz + 2.5, 14, 0xb9a48a, 5, 0.6, 0.3, 8, 0.6, true);
    }
  }

  private updateHud(): void {
    const sim = this.sim;
    const boss = sim.boss;
    const active = boss.state === BossState.Intro || boss.state === BossState.Fight || boss.state === BossState.Dying;
    this.hud.update({
      title: this.title,
      progress: sim.progress,
      army: sim.crowd.count,
      atCap: sim.crowd.count >= UNIT_CAP,
      score: (this.mode === 'endless' ? this.run.score : 0) + sim.score(),
      cannonHp: sim.cannon.hp / sim.cannon.maxHp,
      bossName: active ? boss.stats.name : null,
      bossHp: boss.hp / boss.maxHp,
      bossShield: boss.shield > 0 ? boss.shield / Math.max(1, boss.shieldMax) : 0,
      abilityCooldown: sim.cannon.abilityCd / sim.stats.abilityCooldown,
      abilityActive: sim.cannon.overdrive > 0,
    });
  }

  private updateDebug(): void {
    const s = this.lastStats;
    const mem = (performance as Performance & { memory?: { usedJSHeapSize: number } }).memory;
    this.debugEl!.textContent =
      `${(1000 / this.loop.frameMs).toFixed(0)} fps  ${this.loop.frameMs.toFixed(1)} ms\n` +
      `draws ${s.drawCalls}  tris ${(s.triangles / 1000).toFixed(0)}k\n` +
      `geo ${s.geometries}  tex ${s.textures}\n` +
      `units ${this.sim.crowd.count} (${this.sim.crowd.alive} agents)\n` +
      `enemies ${this.sim.enemies.alive}  inst ${this.crowdView.drawn}\n` +
      `particles ${this.effects.activeParticles}\n` +
      `q ${this.quality.level} x${this.quality.scale.toFixed(2)} pr ${s.pixelRatio.toFixed(2)}\n` +
      `${s.width}x${s.height}  load ${this.assets.loadMs.toFixed(0)} ms` +
      (mem ? `\nheap ${(mem.usedJSHeapSize / 1048576).toFixed(0)} MB` : '');
  }

  /** Hooks for automated tests and the debug console. */
  get debug() {
    return {
      sim: () => this.sim,
      save: () => this.save,
      adapter: () => this.adapter,
      stats: () => ({ ...this.lastStats, frameMs: this.loop.frameMs, quality: this.quality.level, scale: this.quality.scale, loadMs: this.assets.loadMs, particles: this.effects.activeParticles, instances: this.crowdView.drawn }),
      input: this.input,
      /** Run the game forward synchronously (automation: rAF is throttled in hidden tabs). */
      advance: (seconds: number) => {
        for (let i = 0; i < seconds * 60; i++) this.step(1 / 60);
        this.cameraCtl.reset();
      },
      unlockAll: () => {
        this.save.unlocked = LEVEL_COUNT;
      },
    };
  }
}
