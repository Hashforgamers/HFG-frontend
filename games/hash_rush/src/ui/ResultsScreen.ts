import type { RunReward } from '../core/GameState';
import type { RunSummary } from '../gameplay/Simulation';
import { fill, fmt, h, iconButton, stars, type ScreenView } from './dom';

const TIPS = [
  'Tip: multiplier gates are worth more the bigger your army already is.',
  'Tip: steer the cannon — your whole army follows it.',
  'Tip: shoot barrels when enemies are standing next to them.',
  'Tip: step out of the red circles to dodge boss shots.',
  'Tip: upgrades make every level easier — and retries are free.',
  'Tip: save Overdrive for the boss or a big wave.',
];

export interface ResultActions {
  next(): void;
  retry(): void;
  upgrades(): void;
  menu(): void;
}

/** Victory and defeat share one screen. */
export class ResultsScreen implements ScreenView {
  readonly el: HTMLElement;
  private readonly body = h('div.panel.narrow.result');

  constructor(private readonly actions: ResultActions) {
    this.el = h('div.screen.panel-screen.dim', null, this.body);
  }

  private raf = 0;

  /** Roll the score up from zero (skipped when the same result is re-shown). */
  private countUp(el: HTMLElement, target: number): void {
    cancelAnimationFrame(this.raf);
    if (this.lastShown === target) {
      el.textContent = fmt(target);
      return;
    }
    this.lastShown = target;
    const start = performance.now();
    const tick = (now: number) => {
      const k = Math.min(1, (now - start) / 900);
      el.textContent = fmt(target * (1 - Math.pow(1 - k, 3)));
      if (k < 1) this.raf = requestAnimationFrame(tick);
    };
    this.raf = requestAnimationFrame(tick);
  }

  private lastShown = -1;

  show(run: RunSummary, reward: RunReward, hasNext: boolean, submitNote: string, progress = 1, endlessStage = 0): void {
    const won = run.status === 'won';
    const stat = (label: string, value: string) => h('div.stat', null, h('span', null, label), h('b', null, value));
    this.body.className = `panel narrow result ${won ? 'won' : 'lost'}`;
    const scoreEl = h('div.result-score', null, '0');
    this.countUp(scoreEl, run.score);
    fill(
      this.body,
      h('div.result-title', null, endlessStage ? 'RUN OVER' : won ? 'VICTORY' : 'DEFEATED'),
      endlessStage
        ? h('div.result-sub.big', null, `Endless · reached stage ${endlessStage}`)
        : won ? stars(run.stars) : h('div.result-sub', null, `Your cannon was destroyed · ${Math.round(progress * 100)}% of the way`),
      scoreEl,
      reward.newBest ? h('div.badge', null, 'NEW BEST') : null,
      h('div.stats', null,
        stat('Enemies destroyed', fmt(run.enemiesKilled)),
        stat('Peak army', fmt(run.peakArmy)),
        stat('Units lost', fmt(run.unitsLost)),
        stat('Time', `${Math.floor(run.time / 60)}:${String(Math.floor(run.time % 60)).padStart(2, '0')}`),
      ),
      reward.unlockedLevel ? h('div.result-sub.good', null, `Level ${reward.unlockedLevel} unlocked`) : null,
      won ? null : h('div.tip', null, TIPS[Math.floor(run.time) % TIPS.length]!),
      won && hasNext ? iconButton('next', 'NEXT LEVEL', 'primary', this.actions.next) : iconButton('restart', won ? 'PLAY AGAIN' : 'TRY AGAIN', 'primary', this.actions.retry),
      h('div.menu-row', null,
        won && hasNext ? iconButton('restart', 'REPLAY', 'ghost tab', this.actions.retry) : null,
        iconButton('up', 'UPGRADES', 'ghost tab', this.actions.upgrades),
        iconButton('grid', 'MENU', 'ghost tab', this.actions.menu),
      ),
      submitNote ? h('div.note', null, submitNote) : null,
    );
  }
}
