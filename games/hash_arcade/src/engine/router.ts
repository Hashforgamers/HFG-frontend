import { useSyncExternalStore } from 'react';

// Hash routes work from file:// and the app's local asset server alike.
const subscribe = (cb: () => void) => {
  window.addEventListener('hashchange', cb);
  return () => window.removeEventListener('hashchange', cb);
};

/** Route segments, e.g. "#/play/math_blitz" → ["play", "math_blitz"]. */
export function useRoute(): string[] {
  const hash = useSyncExternalStore(subscribe, () => location.hash);
  return hash.replace(/^#\/?/, '').split('/').filter(Boolean);
}

export const go = (path: string) => {
  location.hash = `#/${path}`;
};
