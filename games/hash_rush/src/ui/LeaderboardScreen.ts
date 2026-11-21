import type { LeaderboardEntry } from '../integration/HashArcadeAdapter';
import { button, fill, fmt, h, type ScreenView } from './dom';

export class LeaderboardScreen implements ScreenView {
  readonly el: HTMLElement;
  private readonly body = h('div.board');

  constructor(onBack: () => void) {
    this.el = h('div.screen.panel-screen', null, h('div.panel', null, h('div.panel-head', null, h('h2.title', null, 'Leaderboard'), button('✕', 'close', onBack)), this.body));
  }

  loading(): void {
    this.body.replaceChildren(h('div.note', null, 'Loading…'));
  }

  /** `entries` null = the host keeps its own board; `error` = the request failed. */
  show(entries: LeaderboardEntry[] | null, career: number, note: string, error = false): void {
    const head = h('div.board-me', null, h('span', null, 'Your career score'), h('b', null, fmt(career)));
    if (error || !entries) {
      this.body.replaceChildren(head, h('div.note', null, note));
      return;
    }
    const rows = entries.map((e) =>
      h(`div.board-row${e.isPlayer ? '.me' : ''}${e.rank <= 3 ? `.top.r${e.rank}` : ''}` as 'div', null, h('span.rank', null, `#${e.rank}`), h('span.name', null, e.name), h('b', null, fmt(e.score))),
    );
    fill(this.body, head, ...rows, note ? h('div.note', null, note) : null);
  }
}
