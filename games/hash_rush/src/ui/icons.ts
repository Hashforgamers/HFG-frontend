/** Inline SVG icon set: identical on every device (emoji differ per platform and often look cheap). */
const PATHS = {
  bolt: 'M13 2 4 14h6l-1 8 9-12h-6z',
  fire: 'M12 2c1 4 5 5 5 10a5 5 0 0 1-10 0c0-2 1-3 2-4 0 2 1 3 2 3 1-2-1-5 1-9z',
  bot: 'M11 2h2v3h-2zM7 10a5 5 0 0 1 10 0v1H7zM6 12h12v7a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2zm3 3v2h2v-2zm4 0v2h2v-2z',
  sword: 'M19 3h2v2L10 16l-2-2zM6 14l4 4-2 2-1-1-2 2-2-2 2-2-1-1z',
  shield: 'M12 2 4 5v6c0 5 3.4 9.3 8 11 4.6-1.7 8-6 8-11V5z',
  burst: 'M12 1l2.6 6.4L21 5l-2.4 6.4L23 14l-6 1 .6 6.5L12 18l-5.6 3.5L7 15l-6-1 4.4-2.6L3 5l6.4 2.4z',
  gear: 'M12 8.5a3.5 3.5 0 1 0 0 7 3.5 3.5 0 0 0 0-7zm9 5v-3l-2.3-.5a7 7 0 0 0-.8-1.9l1.3-2-2.1-2.1-2 1.3a7 7 0 0 0-1.9-.8L13.5 2h-3L10 4.300a7 7 0 0 0-1.9.8l-2-1.3L4 5.900l1.3 2a7 7 0 0 0-.8 1.9L2 10.500v3l2.300.5c.2.7.4 1.300.8 1.900l-1.300 2L5.900 20l2-1.300c.6.4 1.200.6 1.900.8l.5 2.500h3l.5-2.300a7 7 0 0 0 1.900-.8l2 1.300 2.100-2.100-1.300-2c.4-.6.6-1.200.8-1.900z',
  trophy: 'M7 3h10v2h3v3a4 4 0 0 1-4 4h-.5a5 5 0 0 1-2.500 2.900V18h3v3H8v-3h3v-3.100A5 5 0 0 1 8.500 12H8a4 4 0 0 1-4-4V5h3zM6 7v1a2 2 0 0 0 1 1.700V7zm11 0v2.700A2 2 0 0 0 18 8V7z',
  grid: 'M4 4h7v7H4zm9 0h7v7h-7zM4 13h7v7H4zm9 0h7v7h-7z',
  up: 'M12 3l8 8h-5v10H9V11H4z',
  lock: 'M7 10V7a5 5 0 0 1 10 0v3h1a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1v-9a1 1 0 0 1 1-1zm2 0h6V7a3 3 0 0 0-6 0z',
  skull: 'M12 2a8 8 0 0 0-8 8c0 3 1.500 5 3 6v3h2v-2h2v2h2v-2h2v2h2v-3c1.500-1 3-3 3-6a8 8 0 0 0-8-8zM9 9a2 2 0 1 1 0 4 2 2 0 0 1 0-4zm6 0a2 2 0 1 1 0 4 2 2 0 0 1 0-4z',
  close: 'M6 4.600l6 6 6-6L19.400 6l-6 6 6 6L18 19.400l-6-6-6 6L4.600 18l6-6-6-6z',
  play: 'M7 4l13 8-13 8z',
  brush: 'M20 2 9 13l2 2L22 4zM7.500 14a3.500 3.500 0 0 0-3.500 3.500c0 1.500-1 2.500-2 3 1 .5 2.500.5 4 .5a5 5 0 0 0 5-5l-1.500-1.500A3.500 3.500 0 0 0 7.500 14z',
  loop: 'M7 8a4 4 0 0 0 0 8c1.700 0 3-1 4.200-2.500L12 12.500l.8 1C14 15 15.300 16 17 16a4 4 0 0 0 0-8c-1.700 0-3 1-4.200 2.500l-.8 1-.8-1C10 9 8.700 8 7 8zm0 2c.9 0 1.800.6 2.900 2-1.100 1.400-2 2-2.900 2a2 2 0 0 1 0-4zm10 0a2 2 0 0 1 0 4c-.9 0-1.800-.6-2.900-2 1.100-1.400 2-2 2.900-2z',
  restart: 'M12 5V1L7 6l5 5V7a5 5 0 1 1-5 5H5a7 7 0 1 0 7-7z',
  exit: 'M10 3H4v18h6v-2H6V5h4zm5.600 4.600L14.200 9l2 2H9v2h7.200l-2 2 1.400 1.400L20 12z',
  next: 'M5 4l9 8-9 8zm11 0h3v16h-3z',
  warn: 'M12 2 1 21h22zm-1 7h2v6h-2zm0 8h2v2h-2z',
  star: 'M12 2l3 6.600 7 .8-5.200 4.800 1.500 7L12 17.600 5.700 21.200l1.500-7L2 9.400l7-.8z',
} as const;

export type IconName = keyof typeof PATHS;

export function icon(name: IconName, cls = ''): HTMLSpanElement {
  const el = document.createElement('span');
  el.className = `ic ${cls}`.trim();
  el.innerHTML = `<svg viewBox="0 0 24 24" aria-hidden="true"><path fill="currentColor" fill-rule="evenodd" d="${PATHS[name]}"/></svg>`;
  return el;
}
