// Talks to the Hash app's WebView when present, falls back to web APIs otherwise.

interface FlutterBridge {
  callHandler(name: string, ...args: unknown[]): Promise<unknown>;
}

const flutter = (): FlutterBridge | undefined =>
  (window as unknown as { flutter_inappwebview?: FlutterBridge }).flutter_inappwebview;

export function haptic(kind: 'light' | 'medium' | 'heavy') {
  const f = flutter();
  if (f) void f.callHandler('haptic', kind).catch(() => {});
  else navigator.vibrate?.(kind === 'heavy' ? [30, 40, 30] : kind === 'medium' ? 20 : 8);
}

export function submitScore(score: number, runId: string) {
  void flutter()?.callHandler('gameScore', { score, runId }).catch(() => {});
}

/** Resolves to what happened so the UI can say "Copied!" when it fell back. */
export async function shareText(text: string): Promise<'shared' | 'copied' | 'failed'> {
  const f = flutter();
  try {
    if (f) {
      const res = (await f.callHandler('share', { text })) as { ok?: boolean } | null;
      if (res?.ok) return 'shared';
    } else if (navigator.share) {
      await navigator.share({ text });
      return 'shared';
    }
  } catch (e) {
    if ((e as Error)?.name === 'AbortError') return 'failed';
  }
  try {
    await navigator.clipboard.writeText(text);
    return 'copied';
  } catch {
    return 'failed';
  }
}

export const store = {
  get(key: string): string | null {
    try {
      return localStorage.getItem(key);
    } catch {
      return null;
    }
  },
  set(key: string, value: string) {
    try {
      localStorage.setItem(key, value);
    } catch {
      /* private mode: bests just aren't kept */
    }
  },
};
