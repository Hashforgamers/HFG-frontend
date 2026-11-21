import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Grid } from '../../ui';
import { cleared, countAround, layMines, layoutFor, reveal } from './logic';

const NUM = ['', '#2e9bff', '#7cf06b', '#ff6f61', '#b9a8ff', '#ffbe7a', '#ff77ae', '#fff', '#fff'];

export default function Minesweeper({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const { cols, rows, mines } = layoutFor(level);
  const [mine, setMine] = useState<boolean[] | null>(null);
  const [open, setOpen] = useState<boolean[]>(() => Array(cols * rows).fill(false));
  const [flags, setFlags] = useState<Set<number>>(new Set());
  const [flagMode, setFlagMode] = useState(false);
  const [boom, setBoom] = useState<number | null>(null);

  const fresh = async (l: number) => {
    const L = layoutFor(l);
    setLevel(l);
    setMine(null);
    setOpen(Array(L.cols * L.rows).fill(false));
    setFlags(new Set());
    setBoom(null);
  };

  const tap = async (i: number) => {
    if (boom != null || open[i]) return;
    if (flagMode) {
      const f = new Set(flags);
      if (f.has(i)) f.delete(i);
      else f.add(i);
      return setFlags(f);
    }
    if (flags.has(i)) return;
    const m = mine ?? layMines(level, i, ctx.rng); // first tap is always safe
    if (!mine) setMine(m);
    if (m[i]) {
      setBoom(i);
      setOpen(m.map((x, k) => x || open[k]));
      ctx.miss({ life: true });
      await ctx.sleep(1500);
      return fresh(level);
    }
    const o = reveal(m, open, i, cols, rows);
    setOpen(o);
    if (cleared(m, o)) {
      ctx.hit(40 * mines);
      ctx.stat('Boards cleared', level);
      await ctx.sleep(600);
      fresh(level + 1);
    }
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-3">
      <div className="flex w-full items-center justify-between">
        <p className="text-sm tracking-widest text-soft">💣 {mines - flags.size} LEFT</p>
        <button onClick={() => setFlagMode(!flagMode)} aria-pressed={flagMode} className={`chunky ${flagMode ? 'tone-red' : 'tone-purple'} outline-text rounded-2xl px-4 py-2`}>
          {flagMode ? '⚑ FLAGGING' : '⚑ FLAG MODE'}
        </button>
      </div>
      <div className="fit-area grid w-full flex-1 place-items-center">
        <Grid
          key={level}
          cols={cols}
          rows={rows}
          label="Minefield"
          className="gap-1"
          onPick={tap}
          render={(i) => {
            if (!open[i]) return { label: flags.has(i) ? 'Flagged' : 'Hidden', className: 'chunky tone-purple grid place-items-center rounded-lg', content: flags.has(i) ? <span className="text-[0.55em] text-danger">⚑</span> : null };
            if (mine?.[i]) return { label: 'Mine', className: `grid place-items-center rounded-lg ${boom === i ? 'bg-danger' : 'bg-black/30'}`, content: <span className="text-[0.55em]">✸</span> };
            const k = mine ? countAround(mine, i, cols, rows) : 0;
            return { label: k ? `${k}` : 'Empty', className: 'grid place-items-center rounded-lg bg-black/25', content: k ? <span className="outline-text text-[0.6em]" style={{ color: NUM[k] }}>{k}</span> : null };
          }}
        />
      </div>
    </div>
  );
}
