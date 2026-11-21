import { useEffect, useRef, useState, type ReactNode } from 'react';
import type { GameDef } from './engine/types';

export function Thumb({ def, size = 'md' }: { def: GameDef; size?: 'md' | 'lg' }) {
  const big = size === 'lg';
  const [art, setArt] = useState(true);
  const symbol = /[^\x00-\x7F]/.test(def.glyph) && !/^[A-Za-zÀ-ÿ]+$/.test(def.glyph);
  // generated art (public/icons) when it exists; the glyph tile is the fallback
  if (art)
    return (
      <img
        src={`icons/${def.id}.webp`}
        alt=""
        aria-hidden
        loading="lazy"
        draggable={false}
        onError={() => setArt(false)}
        className={`block aspect-square w-full border-[3px] border-outline object-cover shadow-[0_6px_12px_rgb(0_0_0/0.4)] ${big ? 'rounded-3xl' : 'rounded-2xl'}`}
      />
    );
  return (
    <div
      aria-hidden
      className={`relative grid aspect-square place-items-center overflow-hidden border-[3px] border-outline ${big ? 'rounded-3xl' : 'rounded-2xl'}`}
      style={{
        // glossy app-icon tile like the Ludo art: colour body, dark lip, top shine
        background: `linear-gradient(180deg, rgb(255 255 255 / 0.28) 0 34%, transparent 34%), linear-gradient(180deg, ${def.accent}, color-mix(in srgb, ${def.accent} 62%, #140c3f))`,
        boxShadow: 'inset 0 -6px 0 rgb(0 0 0 / 0.3), 0 6px 12px rgb(0 0 0 / 0.4)',
      }}
    >
      {/* symbols fall back to the system font and draw smaller than Lilita letters, so size them up */}
      <span
        className={`outline-text leading-none text-white ${symbol ? (big ? 'text-8xl' : 'text-5xl') : big ? 'text-6xl' : 'text-3xl'}`}
        style={symbol ? { fontFamily: 'system-ui, sans-serif', fontWeight: 900 } : undefined}
      >
        {def.glyph}
      </span>
    </div>
  );
}

export function Button({
  children,
  onClick,
  variant = 'primary',
  className = '',
  autoFocus,
}: {
  children: ReactNode;
  onClick: () => void;
  variant?: 'primary' | 'ghost' | 'outline';
  className?: string;
  autoFocus?: boolean;
}) {
  const look = {
    primary: 'chunky tone-green',
    outline: 'chunky tone-yellow',
    ghost: 'chunky tone-purple',
  }[variant];
  return (
    <button onClick={onClick} autoFocus={autoFocus} className={`outline-text rounded-2xl py-3.5 tracking-wider ${look} ${className}`}>
      {children}
    </button>
  );
}

/** Number pad for answer entry; also listens to the physical keyboard. */
export function Keypad({ value, onChange, onSubmit, maxLength = 5 }: {
  value: string;
  onChange: (v: string) => void;
  onSubmit?: () => void;
  maxLength?: number;
}) {
  const latest = useRef({ value, onChange, onSubmit });
  latest.current = { value, onChange, onSubmit };
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const { value: v, onChange: set, onSubmit: submit } = latest.current;
      if (/^\d$/.test(e.key) && v.length < maxLength) set(v + e.key);
      else if (e.key === 'Backspace') set(v.slice(0, -1));
      else if (e.key === 'Enter' && submit) submit();
      else return;
      e.preventDefault();
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [maxLength]);

  const press = (k: string) => {
    if (k === '⌫') onChange(value.slice(0, -1));
    else if (k === 'OK') onSubmit?.();
    else if (value.length < maxLength) onChange(value + k);
  };
  const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '⌫', '0', onSubmit ? 'OK' : ''];
  return (
    <div className="grid w-full max-w-xs grid-cols-3 gap-2">
      {keys.map((k, i) =>
        k ? (
          <button
            key={i}
            aria-label={k === '⌫' ? 'Delete' : k === 'OK' ? 'Submit' : k}
            onPointerDown={(e) => {
              e.preventDefault();
              press(k);
            }}
            className={`outline-text chunky h-14 rounded-2xl text-2xl ${k === 'OK' ? 'tone-green' : 'tone-purple'}`}
          >
            {k}
          </button>
        ) : (
          <span key={i} />
        ),
      )}
    </div>
  );
}

/** Grid that fills a `.fit-area` parent, with roving-tabindex arrow keys. */
export function Grid({ cols, rows, render, onPick, label, className = '' }: {
  cols: number;
  rows: number;
  render: (i: number) => { content?: ReactNode; className?: string; style?: React.CSSProperties; label?: string };
  onPick: (i: number, el: HTMLElement) => void;
  label: string;
  className?: string;
}) {
  const ref = useRef<HTMLDivElement>(null);
  const [focus, setFocus] = useState(0);
  const count = cols * rows;
  const onKeyDown = (e: React.KeyboardEvent) => {
    const step = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -cols, ArrowDown: cols }[e.key];
    if (step === undefined) return;
    e.preventDefault();
    const n = Math.min(count - 1, Math.max(0, focus + step));
    setFocus(n);
    (ref.current?.children[n] as HTMLElement | undefined)?.focus();
  };
  return (
    <div
      ref={ref}
      role="grid"
      aria-label={label}
      className={`fit-grid ${className}`}
      style={{ ['--c' as string]: cols, ['--r' as string]: rows }}
      onKeyDown={onKeyDown}
    >
      {Array.from({ length: count }, (_, i) => {
        const cell = render(i);
        return (
          <button
            key={i}
            tabIndex={i === Math.min(focus, count - 1) ? 0 : -1}
            aria-label={cell.label}
            className={cell.className}
            style={cell.style}
            onPointerDown={(e) => {
              // pointerdown, not click: ~100ms faster per tap
              if (e.button !== 0) return;
              e.preventDefault();
              onPick(i, e.currentTarget);
            }}
            onKeyDown={(e) => {
              if (e.key === 'Enter' || e.key === ' ') {
                e.preventDefault();
                onPick(i, e.currentTarget);
              }
            }}
            onFocus={() => setFocus(i)}
          >
            {cell.content}
          </button>
        );
      })}
    </div>
  );
}

/** Size of an element, for capping grids to a tappable cell size. */
export function useSize(ref: React.RefObject<HTMLElement>) {
  const [size, setSize] = useState({ w: 0, h: 0 });
  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    const ro = new ResizeObserver(() => setSize({ w: el.clientWidth, h: el.clientHeight }));
    ro.observe(el);
    return () => ro.disconnect();
  }, [ref]);
  return size;
}

/** Restart a CSS shake on an element. */
export function shake(el: HTMLElement) {
  el.classList.remove('shake');
  void el.offsetWidth;
  el.classList.add('shake');
}
