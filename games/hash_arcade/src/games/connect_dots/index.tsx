import { useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { adjacent, makeFlow, solvedFlow } from './logic';

const COLORS = ['#ff6f61', '#7cf06b', '#2e9bff', '#ffe45c', '#ff77ae', '#ffffff', '#ffbe7a'];

export default function ConnectDots({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [flow, setFlow] = useState(() => makeFlow(1, ctx.rng));
  const [paths, setPaths] = useState<number[][]>(() => flow.ends.map(() => []));
  const drawing = useRef<number | null>(null);
  const { n, ends } = flow;

  const owner = (cell: number) => paths.findIndex((p) => p.includes(cell));
  const endOf = (cell: number) => ends.findIndex(([a, b]) => a === cell || b === cell);

  const begin = (cell: number) => {
    const k = endOf(cell) >= 0 ? endOf(cell) : owner(cell);
    if (k < 0) return;
    drawing.current = k;
    const p = paths[k];
    // start fresh from an endpoint, or continue from a cell already on the path
    setPaths(paths.map((q, j) => (j === k ? (endOf(cell) === k ? [cell] : p.slice(0, p.indexOf(cell) + 1)) : q)));
  };

  const extend = (cell: number) => {
    const k = drawing.current;
    if (k == null) return;
    const p = paths[k];
    const last = p[p.length - 1];
    if (cell === last || !adjacent(last, cell, n)) return;
    if (p.length > 1 && cell === p[p.length - 2]) return setPaths(paths.map((q, j) => (j === k ? p.slice(0, -1) : q))); // back up
    const end = endOf(cell);
    if (end >= 0 && end !== k) return; // another colour's dot
    if (p.length > 1 && ends[k].includes(last) && last !== p[0]) return; // already reached the far end
    const cut = paths.map((q, j) => (j !== k && q.includes(cell) ? q.slice(0, q.indexOf(cell)) : q)); // crossing cuts the other path
    const next = cut.map((q, j) => (j === k ? [...p, cell] : q));
    setPaths(next);
    if (solvedFlow(flow, next)) win();
  };

  const win = async () => {
    drawing.current = null;
    ctx.hit(60 * ends.length, 15);
    ctx.stat('Boards', level);
    await ctx.sleep(600);
    const f = makeFlow(level + 1, ctx.rng);
    setLevel(level + 1);
    setFlow(f);
    setPaths(f.ends.map(() => []));
  };

  const cellAt = (e: React.PointerEvent) => {
    const el = document.elementFromPoint(e.clientX, e.clientY) as HTMLElement | null;
    const v = el?.closest('[data-cell]')?.getAttribute('data-cell');
    return v == null ? null : Number(v);
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-4">
      <p className="text-center text-sm tracking-widest text-soft">DRAG TO JOIN EACH PAIR · PATHS CAN'T CROSS</p>
      <div
        role="application"
        aria-label="Connect the matching dots"
        onPointerDown={(e) => { const c = cellAt(e); if (c != null) { e.currentTarget.setPointerCapture(e.pointerId); begin(c); } }}
        onPointerMove={(e) => { const c = cellAt(e); if (c != null) extend(c); }}
        onPointerUp={() => (drawing.current = null)}
        className="tray grid aspect-square w-full max-w-[min(100%,56vh)] touch-none gap-1 rounded-3xl p-2"
        style={{ gridTemplateColumns: `repeat(${n}, 1fr)`, gridTemplateRows: `repeat(${n}, 1fr)` }}
      >
        {Array.from({ length: n * n }, (_, i) => {
          const end = endOf(i);
          const k = owner(i);
          const color = end >= 0 ? COLORS[end] : k >= 0 ? COLORS[k] : undefined;
          return (
            <div key={i} data-cell={i} className="grid place-items-center rounded-lg" style={{ background: k >= 0 ? `${COLORS[k]}55` : 'rgb(0 0 0 / 0.2)' }}>
              {end >= 0 && <span className="h-3/5 w-3/5 rounded-full border-[3px] border-outline" style={{ background: color }} />}
            </div>
          );
        })}
      </div>
      <button onClick={() => setPaths(ends.map(() => []))} className="chunky tone-purple outline-text rounded-2xl px-5 py-2">CLEAR</button>
    </div>
  );
}
