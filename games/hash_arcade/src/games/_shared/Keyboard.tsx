import { useEffect, useRef } from 'react';

const ROWS = ['qwertyuiop', 'asdfghjkl', 'zxcvbnm'];

/**
 * On-screen QWERTY that also listens to a physical keyboard. Phones never
 * open their own keyboard over the game. `colors` tints keys (Five-Letter Guess).
 */
export function Keyboard({ onKey, onEnter, onBack, colors = {} }: {
  onKey: (letter: string) => void;
  onEnter?: () => void;
  onBack: () => void;
  colors?: Record<string, string>;
}) {
  const latest = useRef({ onKey, onEnter, onBack });
  latest.current = { onKey, onEnter, onBack };
  useEffect(() => {
    const handle = (e: KeyboardEvent) => {
      if (e.metaKey || e.ctrlKey || e.altKey) return;
      const k = e.key.toLowerCase();
      if (/^[a-z]$/.test(k)) latest.current.onKey(k);
      else if (e.key === 'Backspace') latest.current.onBack();
      else if (e.key === 'Enter' && latest.current.onEnter) latest.current.onEnter();
      else return;
      e.preventDefault();
    };
    window.addEventListener('keydown', handle);
    return () => window.removeEventListener('keydown', handle);
  }, []);

  const key = (label: string, action: () => void, extra = '', wide = false, aria?: string) => (
    <button
      key={label}
      aria-label={aria ?? label}
      onPointerDown={(e) => {
        e.preventDefault();
        action();
      }}
      className={`outline-text h-12 rounded-xl text-lg uppercase ${wide ? 'flex-[1.6] text-sm' : 'flex-1'} ${extra || 'chunky tone-purple'}`}
    >
      {label}
    </button>
  );

  return (
    <div className="flex w-full max-w-md flex-col gap-1.5">
      {ROWS.map((row, r) => (
        <div key={row} className="flex gap-1">
          {r === 2 && onEnter && key('enter', onEnter, 'chunky tone-green', true, 'Enter')}
          {[...row].map((l) => key(l, () => onKey(l), colors[l]))}
          {r === 2 && key('⌫', onBack, 'chunky tone-red', true, 'Delete')}
        </div>
      ))}
    </div>
  );
}
