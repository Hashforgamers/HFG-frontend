import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { makeSudoku, solvedSudoku } from './logic';

export default function MiniSudoku({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [s, setS] = useState(() => makeSudoku(1, ctx.rng));
  const [grid, setGrid] = useState(s.givens);
  const [sel, setSel] = useState(s.givens.indexOf(0));
  const [bad, setBad] = useState(false);
  const { n, boxW, boxH } = s;

  const put = (v: number) => {
    if (s.givens[sel]) return;
    const g = [...grid];
    g[sel] = v;
    setGrid(g);
    setBad(false);
    if (!g.every(Boolean)) return;
    if (solvedSudoku(s, g)) {
      ctx.hit(60 * s.givens.filter((x) => !x).length, 45);
      ctx.stat('Grids solved', level);
      const next = makeSudoku(level + 1, ctx.rng);
      setLevel(level + 1);
      setS(next);
      setGrid(next.givens);
      setSel(next.givens.indexOf(0));
    } else {
      ctx.miss();
      setBad(true);
    }
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-5">
      <p className="text-center text-sm tracking-widest text-soft">1–{n} ONCE IN EVERY ROW, COLUMN AND BOX</p>
      <div className={`grid w-full max-w-[min(100%,50vh)] overflow-hidden rounded-2xl border-[3px] border-outline bg-[#33238a] ${bad ? 'shake' : ''}`} style={{ gridTemplateColumns: `repeat(${n}, 1fr)` }}>
        {grid.map((v, i) => {
          const r = Math.floor(i / n), c = i % n;
          const given = !!s.givens[i];
          return (
            <button
              key={`${level}-${i}`}
              onClick={() => !given && setSel(i)}
              aria-label={`Row ${r + 1} column ${c + 1}${v ? `, ${v}` : ', empty'}${given ? ', given' : ''}`}
              className={`grid aspect-square place-items-center text-3xl ${sel === i ? 'bg-volt/30' : ''} ${given ? 'text-soft' : bad ? 'text-danger' : 'text-white'}`}
              style={{
                borderRight: c < n - 1 ? ((c + 1) % boxW ? '1px solid rgb(255 255 255 / 0.15)' : '3px solid #0b0b10') : undefined,
                borderBottom: r < n - 1 ? ((r + 1) % boxH ? '1px solid rgb(255 255 255 / 0.15)' : '3px solid #0b0b10') : undefined,
              }}
            >
              <span className="outline-text">{v || ''}</span>
            </button>
          );
        })}
      </div>
      <div className="flex flex-wrap justify-center gap-2">
        {Array.from({ length: n }, (_, k) => k + 1).map((v) => (
          <button key={v} onClick={() => put(v)} className="chunky tone-purple outline-text h-14 w-12 rounded-2xl text-2xl">{v}</button>
        ))}
        <button onClick={() => put(0)} aria-label="Clear cell" className="chunky tone-red outline-text h-14 w-12 rounded-2xl text-2xl">⌫</button>
      </div>
    </div>
  );
}
