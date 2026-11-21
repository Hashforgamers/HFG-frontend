import { icon } from './icons';

type Child = Node | string | null | undefined | false;

/** Tiny hyperscript helper: h('div.card.big', { onclick }, child, 'text'). */
export function h<K extends keyof HTMLElementTagNameMap>(
  spec: K | `${K}.${string}`,
  props?: Partial<HTMLElementTagNameMap[K]> | null,
  ...children: Child[]
): HTMLElementTagNameMap[K] {
  const [tag, ...classes] = spec.split('.') as [K, ...string[]];
  const el = document.createElement(tag);
  if (classes.length) el.className = classes.join(' ');
  if (props) Object.assign(el, props);
  for (const child of children) if (child) el.append(child);
  return el;
}

/** replaceChildren that skips empty children. */
export function fill(el: HTMLElement, ...children: Child[]): void {
  el.replaceChildren(...children.filter((c): c is Node | string => !!c));
}

export function button(label: string, cls: string, onClick: () => void): HTMLButtonElement {
  return h(`button.btn.${cls}` as 'button', { type: 'button', onclick: onClick }, label === '✕' ? icon('close') : label);
}

/** Button with a leading icon. */
export function iconButton(name: Parameters<typeof icon>[0], label: string, cls: string, onClick: () => void): HTMLButtonElement {
  return h(`button.btn.row.${cls}` as 'button', { type: 'button', onclick: onClick }, icon(name), h('span', null, label));
}

export function fmt(n: number): string {
  return n >= 1e6 ? (n / 1e6).toFixed(1) + 'M' : n >= 10000 ? (n / 1000).toFixed(1) + 'K' : String(Math.round(n));
}

export function stars(count: number): HTMLElement {
  const el = h('div.stars');
  for (let i = 0; i < 3; i++) el.append(icon('star', `star${i < count ? ' on' : ''}`));
  return el;
}

export interface ScreenView {
  el: HTMLElement;
}
