import { m } from 'framer-motion';
import { useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { shake } from '../../ui';
import type { Op } from '../_shared/fraction';
import { checkBlanks, makeBlanks } from './logic';

export default function MissingOperator({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [eq, setEq] = useState(() => makeBlanks(1, ctx.rng));
  const [ops, setOps] = useState<Op[]>([]);
  const row = useRef<HTMLDivElement>(null);
  const k = eq.nums.length - 1;

  const choose = (op: Op) => {
    const next = [...ops, op];
    if (next.length < k) return setOps(next);
    if (checkBlanks(eq, next)) {
      ctx.hit(80 * k, 2);
      setLevel(level + 1);
      setEq(makeBlanks(level + 1, ctx.rng));
    } else {
      ctx.miss({ seconds: 3 });
      if (row.current) shake(row.current);
    }
    setOps([]);
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-8">
      <p className="text-sm tracking-widest text-soft">FILL IN THE SIGNS · × AND ÷ COME FIRST</p>
      <m.div key={level} ref={row} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className="flex flex-wrap items-center justify-center gap-2 text-4xl tabular-nums">
        {eq.nums.map((v, i) => (
          <span key={i} className="flex items-center gap-2">
            <span className="outline-text">{v}</span>
            {i < k && (
              <span className={`grid h-12 w-12 place-items-center rounded-xl text-3xl ${ops[i] ? 'chunky tone-yellow outline-text' : i === ops.length ? 'tray border-dashed text-volt' : 'tray'}`}>
                {ops[i] ?? '?'}
              </span>
            )}
          </span>
        ))}
        <span className="outline-text">= <span className="text-volt">{eq.target}</span></span>
      </m.div>
      <div className="grid w-full max-w-xs grid-cols-4 gap-3">
        {(['+', '−', '×', '÷'] as Op[]).map((o) => (
          <button key={o} onClick={() => choose(o)} className="chunky tone-green outline-text h-16 rounded-2xl text-4xl">{o}</button>
        ))}
      </div>
      <button disabled={!ops.length} onClick={() => setOps(ops.slice(0, -1))} className="chunky tone-purple outline-text rounded-2xl px-5 py-2 disabled:opacity-40">UNDO</button>
    </div>
  );
}
