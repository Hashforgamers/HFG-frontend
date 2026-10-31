import type { SaveData } from '../core/GameState';
import type { ShopCatalog } from '../integration/HashArcadeAdapter';
import { UPGRADES, UPGRADE_IDS, type UpgradeId } from '../gameplay/Upgrades';
import { button, fmt, h, type ScreenView } from './dom';
import { icon, type IconName } from './icons';

const ICONS: Record<UpgradeId, IconName> = { fireRate: 'fire', startArmy: 'bot', unitDamage: 'sword', unitHealth: 'shield', cannonPower: 'burst', abilityCooldown: 'bolt' };

export class UpgradeScreen implements ScreenView {
  readonly el: HTMLElement;
  private readonly list = h('div.upgrade-list');
  private readonly balance = h('span.credit-num');
  private readonly wallet = h('div.credits', null, h('span.credit-icon'), this.balance);
  private justBought: UpgradeId | null = null;

  constructor(private readonly onBuy: (id: UpgradeId) => void, onBack: () => void) {
    this.el = h(
      'div.screen.panel-screen', null,
      h('div.panel', null,
        h('div.panel-head', null, h('h2.title', null, 'Upgrades'), this.wallet, button('✕', 'close', onBack)),
        this.list,
      ),
    );
  }

  /** `shop` is the host's price list; null while it loads or when the host sells nothing. */
  refresh(save: SaveData, shop: ShopCatalog | null): void {
    const have = shop?.balance ?? null;
    this.wallet.hidden = have == null;
    this.balance.textContent = have == null ? '' : fmt(have);
    this.list.replaceChildren();
    this.list.classList.remove('busy');
    for (const id of UPGRADE_IDS) {
      const def = UPGRADES[id];
      const level = save.upgrades[id];
      const maxed = level >= def.maxLevel;
      const cost = shop?.upgrades[id]?.[level] ?? null;
      const poor = cost == null || (have != null && have < cost);
      const buy = h(
        `button.btn.buy${maxed ? '.maxed' : poor ? '.poor' : '.can'}` as 'button',
        {
          type: 'button',
          onclick: () => {
            this.justBought = id;
            // the host charges over the network: show a spinner and lock the list until it answers
            if (!maxed) {
              buy.classList.add('loading');
              this.list.classList.add('busy');
            }
            this.onBuy(id);
          },
        },
        maxed ? 'MAX' : cost == null ? '—' : h('span', null, h('span.credit-icon'), fmt(cost)),
      );
      buy.disabled = !maxed && cost == null;
      const pips = h('div.pips');
      for (let i = 0; i < def.maxLevel; i++) pips.append(h(`i${i < level ? '.on' : ''}` as 'i'));
      this.list.append(
        h(`div.upgrade${this.justBought === id ? '.bought' : ''}` as 'div', null,
          h(`div.upgrade-icon.u-${id}` as 'div', null, icon(ICONS[id])),
          h('div.upgrade-info', null,
            h('div.upgrade-name', null, def.name, h('span.upgrade-lvl', null, `Lv ${level}`)),
            h('div.upgrade-desc', null, def.desc),
            h('div.upgrade-val', null, def.format(def.value(level)), maxed ? null : h('span.arrow', null, ` → ${def.format(def.value(level + 1))}`)),
            pips,
          ),
          buy,
        ),
      );
    }
    this.justBought = null;
  }
}
