import type { SaveData } from '../core/GameState';
import { careerScore } from '../core/GameState';
import { WORLD_NAMES } from '../levels/LevelConfig';
import { getLevel } from '../levels/LevelManager';
import type { ShopCatalog } from '../integration/HashArcadeAdapter';
import { fmt, h, type ScreenView } from './dom';
import { icon, type IconName } from './icons';
import { BOSS_STATS } from '../gameplay/BossSystem';
import { LEVEL_COUNT } from '../levels/LevelManager';
import { ENDLESS_UNLOCK_LEVEL } from '../levels/Endless';

export interface MenuActions {
  play(): void;
  endless(): void;
  skins(): void;
  levels(): void;
  upgrades(): void;
  leaderboard(): void;
  settings(): void;
}

export class MainMenu implements ScreenView {
  readonly el: HTMLElement;
  private readonly balance = h('span.credit-num');
  private readonly wallet = h('div.credits', null, h('span.credit-icon'), this.balance);
  private readonly playSub = h('span.btn-sub');
  private readonly stats = h('div.menu-stats');
  private readonly card = h('div.next-card');
  private readonly endlessBtn: HTMLButtonElement;
  private readonly endlessSub = h('span.btn-sub');

  constructor(actions: MenuActions) {
    const play = h('button.btn.primary.huge', { type: 'button', onclick: actions.play }, h('span.play-row', null, icon('play'), 'PLAY'), this.playSub);
    const tab = (name: IconName, label: string, fn: () => void) => h('button.dock-tab', { type: 'button', onclick: fn }, icon(name), h('span', null, label));
    this.endlessBtn = h('button.btn.endless', { type: 'button', onclick: actions.endless }, h('span.play-row', null, icon('loop'), 'ENDLESS'), this.endlessSub);
    this.el = h(
      'div.screen.menu', null,
      h('div.menu-top', null, this.wallet, h('span.menu-top-gap'), h('button.icon-btn.gear', { type: 'button', ariaLabel: 'Settings', onclick: actions.settings }, icon('gear'))),
      h('div.logo', null, h('div.logo-hash', null, 'HASH'), h('div.logo-rush', null, 'RUSH')),
      h('div.menu-tag', null, 'Fire. Multiply. Overwhelm.'),
      this.stats,
      h('div.menu-spacer'),
      this.card,
      play,
      this.endlessBtn,
      h('div.dock', null,
        tab('grid', 'LEVELS', actions.levels),
        tab('up', 'UPGRADES', actions.upgrades),
        tab('brush', 'SKINS', actions.skins),
        tab('trophy', 'RANKS', actions.leaderboard),
      ),
    );
  }

  /** `shop` carries the player's balance in the host's currency; the pill hides when the host has none. */
  refresh(save: SaveData, shop: ShopCatalog | null): void {
    const level = getLevel(save.unlocked);
    const have = shop?.balance ?? null;
    this.wallet.hidden = have == null;
    this.balance.textContent = have == null ? '' : fmt(have);
    this.playSub.textContent = `Level ${level.id} · ${WORLD_NAMES[level.world]}`;
    const open = save.unlocked > ENDLESS_UNLOCK_LEVEL;
    this.endlessBtn.disabled = !open;
    this.endlessBtn.classList.toggle('locked', !open);
    this.endlessSub.textContent = !open
      ? `Clear level ${ENDLESS_UNLOCK_LEVEL} to unlock`
      : save.endless.stage > 0 ? `Best: stage ${save.endless.stage} · ${fmt(save.endless.score)} pts` : 'How far can you go?';
    let starCount = 0;
    let cleared = 0;
    for (const key of Object.keys(save.best)) {
      starCount += save.best[Number(key)]!.stars;
      cleared++;
    }
    const stat = (name: IconName, value: string, label: string) => h('div.menu-stat', null, icon(name), h('b', null, value), h('span', null, label));
    this.stats.replaceChildren(
      stat('star', `${starCount}/${LEVEL_COUNT * 3}`, 'STARS'),
      stat('grid', `${cleared}/${LEVEL_COUNT}`, 'CLEARED'),
      stat('trophy', fmt(careerScore(save)), 'SCORE'),
    );
    const fill = h('i');
    fill.style.width = `${(cleared / LEVEL_COUNT) * 100}%`;
    this.card.className = `next-card w-${level.world}`;
    this.card.replaceChildren(
      h('div.next-main', null,
        h('div.next-kicker', null, `UP NEXT · LEVEL ${level.id}`),
        h('div.next-name', null, level.name),
        h('div.next-progress', null, fill),
      ),
      h('div.next-boss', null, icon('skull'), h('span', null, 'BOSS'), h('b', null, BOSS_STATS[level.boss.kind].name)),
    );
  }
}
