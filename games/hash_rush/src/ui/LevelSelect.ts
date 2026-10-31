import type { SaveData } from '../core/GameState';
import { WORLD_NAMES } from '../levels/LevelConfig';
import { LEVEL_COUNT, getLevel } from '../levels/LevelManager';
import { button, h, stars, type ScreenView } from './dom';
import { icon } from './icons';
import { WORLD_ORDER } from '../levels/LevelConfig';

export class LevelSelect implements ScreenView {
  readonly el: HTMLElement;
  private readonly grid = h('div.level-grid');

  constructor(private readonly onPick: (level: number) => void, onBack: () => void) {
    this.el = h('div.screen.panel-screen', null, h('div.panel', null, h('div.panel-head', null, h('h2.title', null, 'Select Level'), button('✕', 'close', onBack)), this.grid));
  }

  refresh(save: SaveData): void {
    this.grid.replaceChildren();
    // each column is one world
    for (const world of WORLD_ORDER) this.grid.append(h('div.level-head', null, WORLD_NAMES[world].split(' ')[0]!.toUpperCase()));
    for (let n = 1; n <= LEVEL_COUNT; n++) {
      const level = getLevel(n);
      const locked = n > save.unlocked;
      const best = save.best[n];
      const tile = h(
        `button.level-tile.w-${level.world}${locked ? '.locked' : ''}${n === save.unlocked ? '.current' : ''}` as 'button',
        { type: 'button', disabled: locked, title: `${level.name} — ${WORLD_NAMES[level.world]}` },
        locked ? icon('lock', 'level-lock') : h('span.level-num', null, String(n)),
        h('span.level-boss', null, level.boss.kind === 'titan' ? 'TITAN' : level.boss.kind === 'inferno' ? 'INFERNO' : 'VOID'),
        stars(best?.stars ?? 0),
      );
      if (!locked) tile.onclick = () => this.onPick(n);
      this.grid.append(tile);
    }
  }
}
