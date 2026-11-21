import { h, fmt } from './dom';
import { icon } from './icons';

export interface HudState {
  /** e.g. "LEVEL 3 · Cold Front" or "ENDLESS · STAGE 2". */
  title: string;
  progress: number;
  army: number;
  atCap: boolean;
  score: number;
  cannonHp: number;
  bossName: string | null;
  bossHp: number;
  bossShield: number;
  /** 0 = ready, 1 = just used. */
  abilityCooldown: number;
  abilityActive: boolean;
}

const FLOATERS = 14;

/** In-game overlay. Values are only written to the DOM when they change. */
export class HUD {
  readonly el: HTMLElement;
  private readonly levelEl: HTMLElement;
  private readonly progressFill: HTMLElement;
  private readonly armyEl: HTMLElement;
  private readonly armyWrap: HTMLElement;
  private readonly scoreEl: HTMLElement;
  private readonly hpFill: HTMLElement;
  private readonly hpNum: HTMLElement;
  private readonly bossWrap: HTMLElement;
  private readonly bossName: HTMLElement;
  private readonly bossFill: HTMLElement;
  private readonly bossShield: HTMLElement;
  private readonly abilityBtn: HTMLButtonElement;
  private readonly abilityRing: HTMLElement;
  private readonly banner: HTMLElement;
  private readonly hint: HTMLElement;
  private readonly vignette: HTMLElement;
  private readonly floaters: HTMLElement[] = [];
  private floaterCursor = 0;
  private last: Partial<HudState> = {};
  private bannerTimer = 0;
  private readonly introEl = h('div.intro');
  private readonly warnEl = h('div.warn-band');
  private introTimer = 0;
  private warnTimer = 0;

  constructor(onPause: () => void, onAbility: () => void) {
    this.levelEl = h('div.hud-level');
    this.progressFill = h('div.hud-progress-fill');
    this.scoreEl = h('div.hud-score', null, '0');
    this.armyEl = h('span.hud-army-num', null, '0');
    this.armyWrap = h('div.hud-army', null, h('span.hud-army-icon'), this.armyEl);
    this.hpFill = h('div.bar-fill.hp');
    this.hpNum = h('span.hp-num', null, '100');
    this.bossName = h('div.boss-name');
    this.bossFill = h('div.bar-fill.boss');
    this.bossShield = h('div.bar-fill.shield');
    this.bossWrap = h('div.boss-bar.hidden', null, this.bossName, h('div.bar', null, this.bossFill, this.bossShield));
    this.abilityRing = h('div.ability-ring');
    this.abilityBtn = h('button.ability', { type: 'button', ariaLabel: 'Overdrive' }, this.abilityRing, icon('bolt', 'ability-icon'), h('span.ability-label', null, 'OVERDRIVE'));
    // pointerdown, not click: no 300 ms delay and it works while another finger is steering
    this.abilityBtn.addEventListener('pointerdown', (e) => {
      e.stopPropagation();
      onAbility();
    });
    this.banner = h('div.banner');
    this.hint = h('div.hint.hidden', null, h('span.hint-hand'), 'Drag to steer your cannon');
    this.vignette = h('div.vignette');
    const pause = h('button.icon-btn.pause', { type: 'button', ariaLabel: 'Pause' }, h('span'), h('span'));
    pause.addEventListener('pointerdown', (e) => {
      e.stopPropagation();
      onPause();
    });
    const floatLayer = h('div.floaters');
    for (let i = 0; i < FLOATERS; i++) {
      const f = h('div.floater');
      this.floaters.push(f);
      floatLayer.append(f);
    }
    this.el = h(
      'div.hud.hidden', null,
      this.vignette,
      h('div.hud-top', null,
        pause,
        h('div.hud-mid', null, this.levelEl, h('div.hud-progress', null, this.progressFill, icon('skull', 'hud-progress-boss'))),
        h('div.hud-score-wrap', null, h('div.hud-score-label', null, 'SCORE'), this.scoreEl),
      ),
      this.bossWrap,
      this.armyWrap,
      floatLayer,
      this.banner,
      this.introEl,
      this.warnEl,
      this.hint,
      h('div.hud-bottom', null, h('div.hp-wrap', null, h('span.hp-label', null, 'CANNON ', this.hpNum), h('div.bar', null, this.hpFill)), this.abilityBtn),
    );
  }

  show(visible: boolean): void {
    this.el.classList.toggle('hidden', !visible);
  }

  reset(): void {
    this.last = {};
    this.banner.classList.remove('show');
    this.introEl.classList.remove('show');
    this.warnEl.classList.remove('show');
    this.vignette.classList.remove('low');
    this.hint.classList.add('hidden');
    for (const f of this.floaters) f.classList.remove('go');
  }

  showHint(visible: boolean): void {
    this.hint.classList.toggle('hidden', !visible);
  }

  update(s: HudState): void {
    const l = this.last;
    if (l.title !== s.title) this.levelEl.textContent = s.title;
    if (l.progress === undefined || Math.abs(l.progress - s.progress) > 0.004) {
      this.progressFill.style.transform = `scaleX(${s.progress.toFixed(3)})`;
      l.progress = s.progress;
    }
    if (l.army !== s.army) {
      this.armyEl.textContent = fmt(s.army);
      if (l.army !== undefined && s.army > l.army) {
        this.armyWrap.classList.remove('bump');
        void this.armyWrap.offsetWidth;
        this.armyWrap.classList.add('bump');
      }
    }
    if (l.atCap !== s.atCap) this.armyWrap.classList.toggle('cap', s.atCap);
    if (l.score !== s.score) this.scoreEl.textContent = fmt(s.score);
    if (l.cannonHp !== s.cannonHp) {
      this.hpFill.style.transform = `scaleX(${Math.max(0, s.cannonHp).toFixed(3)})`;
      this.hpFill.classList.toggle('low', s.cannonHp < 0.35);
      this.vignette.classList.toggle('low', s.cannonHp < 0.35 && s.cannonHp > 0);
      this.hpNum.textContent = String(Math.ceil(Math.max(0, s.cannonHp) * 100));
    }
    if (l.bossName !== s.bossName) {
      this.bossWrap.classList.toggle('hidden', !s.bossName);
      this.bossName.textContent = s.bossName ?? '';
    }
    if (l.bossHp !== s.bossHp) this.bossFill.style.transform = `scaleX(${Math.max(0, s.bossHp).toFixed(3)})`;
    if (l.bossShield !== s.bossShield) this.bossShield.style.transform = `scaleX(${Math.max(0, s.bossShield).toFixed(3)})`;
    if (l.abilityCooldown !== s.abilityCooldown) {
      this.abilityRing.style.setProperty('--cd', String(Math.round(s.abilityCooldown * 360)));
      this.abilityBtn.classList.toggle('ready', s.abilityCooldown <= 0);
    }
    if (l.abilityActive !== s.abilityActive) this.abilityBtn.classList.toggle('active', s.abilityActive);
    const progress = l.progress;
    Object.assign(l, s);
    l.progress = progress;
  }

  /** Short text that floats up from a point on the stage (stage pixels). */
  float(text: string, x: number, y: number, color: string, big = false): void {
    const f = this.floaters[this.floaterCursor]!;
    this.floaterCursor = (this.floaterCursor + 1) % FLOATERS;
    f.textContent = text;
    f.style.color = color;
    f.style.left = `${x.toFixed(0)}px`;
    f.style.top = `${y.toFixed(0)}px`;
    f.classList.toggle('big', big);
    f.classList.remove('go');
    void f.offsetWidth;
    f.classList.add('go');
  }

  announce(text: string, tone: 'info' | 'danger' | 'good' = 'info', ms = 1800): void {
    this.banner.textContent = text;
    this.banner.className = `banner show ${tone}`;
    window.clearTimeout(this.bannerTimer);
    this.bannerTimer = window.setTimeout(() => this.banner.classList.remove('show'), ms);
  }

  /** Level title card shown as a run starts. */
  intro(label: string, name: string, world: string, kicker: string, boss: string): void {
    this.introEl.className = `intro show w-${world}`;
    this.introEl.replaceChildren(
      h('div.intro-kicker', null, kicker.toUpperCase()),
      h('div.intro-level', null, label),
      h('div.intro-name', null, name),
      h('div.intro-boss', null, icon('skull'), `Boss: ${boss}`),
    );
    window.clearTimeout(this.introTimer);
    this.introTimer = window.setTimeout(() => this.introEl.classList.remove('show'), 1900);
  }

  /** Full-width hazard band when the boss arrives. */
  bossWarning(name: string): void {
    this.warnEl.replaceChildren(h('div.warn-strip'), h('div.warn-text', null, icon('warn'), h('span', null, 'WARNING'), h('b', null, name.toUpperCase())), h('div.warn-strip'));
    this.warnEl.classList.add('show');
    window.clearTimeout(this.warnTimer);
    this.warnTimer = window.setTimeout(() => this.warnEl.classList.remove('show'), 2400);
  }

  damageFlash(): void {
    this.vignette.classList.remove('hit');
    void this.vignette.offsetWidth;
    this.vignette.classList.add('hit');
  }
}
