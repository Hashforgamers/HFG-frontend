import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { lineBetween, makeSearch, wordAt } from './logic';

export default function WordSearch({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [s, setS] = useState(() => makeSearch(1, ctx.rng));
  const [found, setFound] = useState<number[]>([]);
  const [from, setFrom] = useState<number | null>(null);
  const [hover, setHover] = useState<number | null>(null);
  const { n } = s;

  const finish = async (to: number) => {
    if (from == null) return;
    const line = lineBetween(from, to, n);
    setFrom(null);
    setHover(null);
    if (!line || line.length < 3) return;
    const k = wordAt(s, line);
    if (k < 0 || found.includes(k)) return ctx.miss();
    const f = [...found, k];
    setFound(f);
    ctx.hit(20 * s.words[k].length);
    if (f.length === s.words.length) {
      ctx.hit(100, 30);
      ctx.stat('Grids cleared', level);
      await ctx.sleep(500);
      setLevel(level + 1);
      setS(makeSearch(level + 1, ctx.rng));
      setFound([]);
    }
  };

  const cellAt = (e: React.PointerEvent) => {
    const v = (document.elementFromPoint(e.clientX, e.clientY) as HTMLElement | null)?.closest('[data-cell]')?.getAttribute('data-cell');
    return v == null ? null : Number(v);
  };

  const live = from != null && hover != null ? lineBetween(from, hover, n) ?? [from] : from != null ? [from] : [];
  const foundCells = new Set(found.flatMap((k) => s.places[k]));
  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-3">
      <div className="flex flex-wrap justify-center gap-x-3 gap-y-1">
        {s.words.map((w, k) => (
          <span key={w} className={`text-lg uppercase ${found.includes(k) ? 'text-neon line-through' : 'outline-text'}`}>{w}</span>
        ))}
      </div>
      <div
        role="application"
        aria-label="Word search grid. Drag across a word."
        onPointerDown={(e) => { const c = cellAt(e); if (c != null) { e.currentTarget.setPointerCapture(e.pointerId); setFrom(c); setHover(c); } }}
        onPointerMove={(e) => { if (from == null) return; const c = cellAt(e); if (c != null) setHover(c); }}
        onPointerUp={(e) => { const c = cellAt(e); void finish(c ?? hover ?? -1); }}
        className="tray grid aspect-square w-full max-w-[min(100%,56vh)] touch-none gap-0.5 rounded-3xl p-2"
        style={{ gridTemplateColumns: `repeat(${n}, 1fr)`, gridTemplateRows: `repeat(${n}, 1fr)` }}
      >
        {s.grid.map((l, i) => (
          <span
            key={i}
            data-cell={i}
            className={`grid place-items-center rounded-lg text-2xl uppercase ${live.includes(i) ? 'bg-volt text-ink' : foundCells.has(i) ? 'bg-neon/40' : ''}`}
          >
            {l}
          </span>
        ))}
      </div>
    </div>
  );
}
