import { useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Keypad, shake } from '../../ui';
import { checkCross, makeCross } from './logic';

export default function CrossMath({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [cross, setCross] = useState(() => makeCross(1, ctx.rng));
  const [entries, setEntries] = useState<Record<number, string>>({});
  const [sel, setSel] = useState(cross.blanks[0]);
  const board = useRef<HTMLDivElement>(null);

  const vals = cross.vals.map((v, i) => (cross.blanks.includes(i) ? Number(entries[i] || NaN) : v));
  const filled = cross.blanks.every((i) => entries[i]);

  const submit = () => {
    if (!filled) return;
    if (checkCross(cross, vals)) {
      ctx.hit(120 * cross.blanks.length, 6);
      ctx.stat('Grids solved', level);
      const c = makeCross(level + 1, ctx.rng);
      setLevel(level + 1);
      setCross(c);
      setEntries({});
      setSel(c.blanks[0]);
    } else {
      ctx.miss({ seconds: 3 });
      if (board.current) shake(board.current);
    }
  };

  const cell = (i: number) => {
    const blank = cross.blanks.includes(i);
    return blank ? (
      <button
        onClick={() => setSel(i)}
        aria-label={`Blank ${i + 1}`}
        className={`grid h-16 w-16 place-items-center rounded-2xl text-3xl tabular-nums ${sel === i ? 'chunky tone-yellow outline-text' : 'tray text-volt'}`}
      >
        {entries[i] ?? '?'}
      </button>
    ) : (
      <span className="chunky tone-purple outline-text grid h-16 w-16 place-items-center rounded-2xl text-3xl tabular-nums">{cross.vals[i]}</span>
    );
  };
  const sym = (t: string | number, cls = '') => <span className={`grid h-16 w-10 place-items-center text-3xl ${cls}`}>{t}</span>;
  const [r1, r2, c1, c2] = cross.ops;

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-between gap-3 pb-2">
      <div ref={board} className="flex flex-1 flex-col items-center justify-center">
        <div className="grid grid-cols-[auto_auto_auto_auto_auto] place-items-center gap-1">
          {cell(0)}{sym(r1)}{cell(1)}{sym('=')}{sym(cross.results[0], 'text-volt outline-text')}
          {sym(c1)}<span />{sym(c2)}<span /><span />
          {cell(2)}{sym(r2)}{cell(3)}{sym('=')}{sym(cross.results[1], 'text-volt outline-text')}
          {sym('=')}<span />{sym('=')}<span /><span />
          {sym(cross.results[2], 'text-volt outline-text')}<span />{sym(cross.results[3], 'text-volt outline-text')}<span /><span />
        </div>
      </div>
      <Keypad
        value={entries[sel] ?? ''}
        maxLength={3}
        onChange={(v) => setEntries({ ...entries, [sel]: v })}
        onSubmit={submit}
      />
    </div>
  );
}
