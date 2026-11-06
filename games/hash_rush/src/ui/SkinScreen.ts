import type { SaveData } from '../core/GameState';
import type { ShopCatalog } from '../integration/HashArcadeAdapter';
import { SKINS, type SkinKind } from '../gameplay/Skins';
import { button, fmt, h, type ScreenView } from './dom';
import { icon } from './icons';

/** Skin shop: a bottom sheet, so the cannon and squad stay visible above it as a live preview. */
export class SkinScreen implements ScreenView {
  readonly el: HTMLElement;
  private readonly grid = h('div.skin-grid');
  private readonly balance = h('span.credit-num');
  private readonly wallet = h('div.credits', null, h('span.credit-icon'), this.balance);
  private readonly tabs = h('div.segmented');
  private kind: SkinKind = 'army';
  private save: SaveData | null = null;
  private shop: ShopCatalog | null = null;

  constructor(private readonly onPick: (kind: SkinKind, id: string) => void, onBack: () => void) {
    this.el = h(
      'div.screen.sheet-screen', null,
      h('div.panel.sheet', null,
        h('div.panel-head', null, h('h2.title', null, 'Skins'), this.wallet, button('✕', 'close', onBack)),
        this.tabs,
        this.grid,
      ),
    );
  }

  /** `shop` is the host's price list; null while it loads or when the host sells nothing. */
  refresh(save: SaveData, shop: ShopCatalog | null): void {
    this.save = save;
    this.shop = shop;
    const have = shop?.balance ?? null;
    this.wallet.hidden = have == null;
    this.balance.textContent = have == null ? '' : fmt(have);
    this.tabs.replaceChildren();
    for (const kind of ['army', 'cannon'] as const) {
      const tab = h(`button${this.kind === kind ? '.on' : ''}` as 'button', { type: 'button' }, kind === 'army' ? 'ARMY' : 'CANNON');
      tab.onclick = () => {
        this.kind = kind;
        if (this.save) this.refresh(this.save, this.shop);
      };
      this.tabs.append(tab);
    }
    const kind = this.kind;
    this.grid.replaceChildren();
    this.grid.classList.remove('busy');
    for (const skin of SKINS) {
      const owned = save.skins.owned[kind].includes(skin.id);
      const equipped = save.skins[kind] === skin.id;
      const swatch = h('div.skin-swatch');
      swatch.style.background = `linear-gradient(145deg, ${skin.swatch[0]} 0 62%, ${skin.swatch[1]} 62%)`;
      const state = equipped
        ? h('span.skin-state.on', null, 'EQUIPPED')
        : owned
          ? h('span.skin-state', null, 'EQUIP')
          : this.priceTag(shop?.skins[skin.id] ?? null, have);
      const card = h(`button.skin${equipped ? '.equipped' : ''}` as 'button', { type: 'button' }, swatch, h('span.skin-name', null, skin.name), state);
      card.onclick = () => {
        // buying goes through the host: show a spinner and lock the grid until it answers
        if (!owned) {
          state.classList.add('loading');
          this.grid.classList.add('busy');
        }
        this.onPick(kind, skin.id);
      };
      this.grid.append(card);
    }
  }

  private priceTag(price: number | null, have: number | null): HTMLElement {
    if (price == null) return h('span.skin-state.price.poor', null, icon('lock'));
    const poor = have != null && have < price;
    return h(`span.skin-state.price${poor ? '.poor' : ''}` as 'span', null, poor ? icon('lock') : h('span.credit-icon'), fmt(price));
  }
}
