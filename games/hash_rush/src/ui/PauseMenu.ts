import { fmt, h, iconButton, type ScreenView } from './dom';

export interface PauseInfo {
  title: string;
  progress: number;
  army: number;
  score: number;
}

export class PauseMenu implements ScreenView {
  readonly el: HTMLElement;
  private readonly info = h('div.pause-info');

  constructor(actions: { resume(): void; restart(): void; settings(): void; quit(): void }) {
    this.el = h(
      'div.screen.panel-screen.dim', null,
      h('div.panel.narrow', null,
        h('h2.title', null, 'Paused'),
        this.info,
        iconButton('play', 'RESUME', 'primary', actions.resume),
        iconButton('restart', 'RESTART', 'ghost', actions.restart),
        iconButton('gear', 'SETTINGS', 'ghost', actions.settings),
        iconButton('exit', 'QUIT TO MENU', 'ghost danger', actions.quit),
      ),
    );
  }

  refresh(p: PauseInfo): void {
    const cell = (label: string, value: string) => h('div.stat', null, h('span', null, label), h('b', null, value));
    this.info.replaceChildren(
      h('div.pause-level', null, p.title),
      h('div.stats.three', null, cell('Progress', `${Math.round(p.progress * 100)}%`), cell('Army', fmt(p.army)), cell('Score', fmt(p.score))),
    );
  }
}
