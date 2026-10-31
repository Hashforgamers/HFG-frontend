import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { makeNonogram, matchesClues } from './logic';

export default function Nonogram({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [p, setP] = useState(() => makeNonogram(1, ctx.rng));
  const [grid, setGrid] = useState<boolean[]>(() => Array(p.n * p.n).fill(false));
  const { n } = p;

  const toggle = async (i: number) => {
    const g = grid.map((v, k) => (k === i ? !v : v));
    setGrid(g);
    if (matchesClues(p, g)) {
      ctx.hit(30 * n * n, 30);
      ctx.stat('Pictures', level);
      await ctx.sleep(500);
      const next = makeNonogram(level + 1, ctx.rng);
      setLevel(level + 1);
      setP(next);
      setGrid(Array(next.n * next.n).fill(false));
    }
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-4">
      <p className="text-center text-sm tracking-widest text-soft">NUMBERS ARE THE RUNS OF FILLED SQUARES, IN ORDER</p>
      <div className="grid w-full max-w-[min(100%,56vh)] gap-1" style={{ gridTemplateColumns: `auto repeat(${n}, 1fr)` }}>
        <span />
        {p.cols.map((c, k) => (
          <span key={k} className="flex flex-col items-center justify-end text-sm leading-tight text-volt">{c.map((v, j) => <span key={j}>{v}</span>)}</span>
        ))}
        {Array.from({ length: n }, (_, r) => (
          <div key={r} className="contents">
            <span className="flex items-center justify-end gap-1 pr-1 text-sm text-volt">{p.rows[r].join(' ')}</span>
            {Array.from({ length: n }, (_, c) => {
              const i = r * n + c;
              return (
                <button
                  key={c}
                  onClick={() => toggle(i)}
                  aria-label={`Row ${r + 1} column ${c + 1}, ${grid[i] ? 'filled' : 'empty'}`}
                  aria-pressed={grid[i]}
                  className={`aspect-square rounded-md ${grid[i] ? 'chunky tone-green' : 'tray'}`}
                />
              );
            })}
          </div>
        ))}
      </div>
      <button onClick={() => setGrid(Array(n * n).fill(false))} className="chunky tone-purple outline-text rounded-2xl px-5 py-2">CLEAR</button>
    </div>
  );
}
