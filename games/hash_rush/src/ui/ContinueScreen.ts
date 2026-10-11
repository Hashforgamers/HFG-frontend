import type { ContinueOffer } from '../integration/HashArcadeAdapter';
import { fmt, h, iconButton, type ScreenView } from './dom';

const SECONDS = 9;

/** Shown when the cannon is destroyed: pay the host's currency to revive, or give up. */
export class ContinueScreen implements ScreenView {
  readonly el: HTMLElement;
  private readonly cost = h('b');
  private readonly currency = h('span');
  private readonly ring = h('div.count-ring');
  private readonly num = h('div.count-num');
  private readonly note = h('div.note');
  private readonly payBtn: HTMLButtonElement;
  private timer = 0;
  private left = SECONDS;

  constructor(private readonly actions: { pay(): void; decline(): void }) {
    this.payBtn = h('button.btn.primary.pay', { type: 'button', onclick: () => this.actions.pay() }, h('span', null, 'CONTINUE'), h('span.pay-cost', null, h('span.credit-icon'), this.cost, this.currency));
    this.el = h(
      'div.screen.panel-screen.dim', null,
      h('div.panel.narrow.continue', null,
        h('h2.title', null, 'Continue?'),
        h('div.count', null, this.ring, this.num),
        h('div.result-sub', null, 'Revive your cannon right here. Your army, progress and score are kept.'),
        this.payBtn,
        iconButton('close', 'NO THANKS', 'ghost', () => this.actions.decline()),
        this.note,
      ),
    );
  }

  show(offer: ContinueOffer): void {
    this.cost.textContent = fmt(offer.cost);
    this.currency.textContent = ` ${offer.currency}`;
    this.note.textContent = '';
    this.payBtn.disabled = false;
    this.left = SECONDS;
    this.tick();
    window.clearInterval(this.timer);
    this.timer = window.setInterval(() => {
      this.left--;
      this.tick();
      if (this.left <= 0) {
        this.stop();
        this.actions.decline();
      }
    }, 1000);
  }

  private tick(): void {
    this.num.textContent = String(Math.max(0, this.left));
    this.ring.style.setProperty('--left', String((this.left / SECONDS) * 360));
  }

  /** Payment in progress: stop the countdown so it cannot expire under the player. */
  busy(): void {
    this.stop();
    this.payBtn.disabled = true;
    this.note.textContent = 'Processing…';
  }

  failed(): void {
    this.payBtn.disabled = false;
    this.note.textContent = 'Not charged. You can try again or skip.';
  }

  stop(): void {
    window.clearInterval(this.timer);
  }
}
