import { useMemo, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { checkKenKen, makeKenKen } from './logic';

export default function KenKenGame({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [puzzle, setPuzzle] = useState(() => makeKenKen(1, ctx.rng));
  const { n, cages } = puzzle;
  const [grid, setGrid] = useState<number[]>(() => Array(n * n).fill(0));
  const [sel, setSel] = useState(0);
  const [bad, setBad] = useState(false);

  const owner = useMemo(() => {
    const o: number[] = [];
    cages.forEach((c, ci) => c.cells.forEach((i) => (o[i] = ci)));
    return o;
  }, [cages]);

  const put = (v: number) => {
    const g = [...grid];
    g[sel] = v;
    setGrid(g);
    setBad(false);
    if (g.every(Boolean)) {
      if (checkKenKen(puzzle, g)) {
        ctx.hit(100 * n, 60);
        ctx.stat('Puzzles solved', level);
        const p = makeKenKen(level + 1, ctx.rng);
        setLevel(level + 1);
        setPuzzle(p);
        setGrid(Array(p.n * p.n).fill(0));
        setSel(0);
      } else {
        ctx.miss();
        setBad(true);
      }
    }
  };

  // thick borders where the neighbour is in another cage
  const border = (i: number) => {
    const r = Math.floor(i / n), c = i % n;
    const edge = (j: number, ok: boolean) => (ok && owner[j] === owner[i] ? '1px solid rgb(255 255 255 / 0.15)' : '3px solid #0b0b10');
    return {
      borderTop: edge(i - n, r > 0),
      borderBottom: edge(i + n, r < n - 1),
      borderLeft: edge(i - 1, c > 0),
      borderRight: edge(i + 1, c < n - 1),
    };
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-5">
      <p className="text-sm tracking-widest text-soft">EACH ROW & COLUMN USES 1–{n} ONCE</p>
      <div className={`grid w-full max-w-[min(100%,52vh)] overflow-hidden rounded-2xl bg-[#33238a] ${bad ? 'shake' : ''}`} style={{ gridTemplateColumns: `repeat(${n}, 1fr)` }}>
        {grid.map((v, i) => {
          const cage = cages[owner[i]];
          const head = Math.min(...cage.cells) === i;
          return (
            <button
              key={i}
              onClick={() => setSel(i)}
              aria-label={`Row ${Math.floor(i / n) + 1} column ${(i % n) + 1}${head ? `, cage ${cage.target}${cage.op}` : ''}`}
              className={`relative grid aspect-square place-items-center text-3xl tabular-nums ${sel === i ? 'bg-volt/30' : ''} ${bad ? 'text-danger' : 'text-white'}`}
              style={border(i)}
            >
              {head && <span className="absolute left-1 top-0.5 text-xs text-volt">{cage.target}{cage.op}</span>}
              <span className="outline-text">{v || ''}</span>
            </button>
          );
        })}
      </div>
      <div className="flex flex-wrap justify-center gap-2">
        {Array.from({ length: n }, (_, k) => k + 1).map((v) => (
          <button key={v} onClick={() => put(v)} className="chunky tone-purple outline-text h-14 w-14 rounded-2xl text-2xl">{v}</button>
        ))}
        <button onClick={() => { const g = [...grid]; g[sel] = 0; setGrid(g); }} aria-label="Clear cell" className="chunky tone-red outline-text h-14 w-14 rounded-2xl text-2xl">⌫</button>
      </div>
    </div>
  );
}
