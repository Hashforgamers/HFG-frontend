import { m } from 'framer-motion';
import { useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { shake } from '../../ui';
import { Keyboard } from '../_shared/Keyboard';
import { acceptGap, makeGap } from './logic';

export default function MissingLetter({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [gap, setGap] = useState(() => makeGap(1, ctx.rng));
  const [fills, setFills] = useState<string[]>([]);
  const row = useRef<HTMLDivElement>(null);

  const key = (l: string) => {
    const f = [...fills, l];
    if (f.length < gap.holes.length) return setFills(f);
    if (acceptGap(gap, f)) {
      ctx.hit(70 * gap.holes.length, 2);
      setLevel(level + 1);
      setGap(makeGap(level + 1, ctx.rng));
    } else {
      ctx.miss({ seconds: 3 });
      if (row.current) shake(row.current);
    }
    setFills([]);
  };

  let hole = 0;
  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-4">
      <p className="text-sm tracking-widest text-soft">FILL THE GAP{gap.holes.length > 1 ? 'S' : ''} TO MAKE A WORD</p>
      <m.div key={level} ref={row} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className="flex flex-1 items-center gap-1.5">
        {[...gap.word].map((c, i) => {
          const isHole = gap.holes.includes(i);
          const v = isHole ? fills[hole++] : c;
          return (
            <span key={i} className={`grid h-14 w-11 place-items-center rounded-xl text-3xl uppercase ${isHole ? 'tray border-dashed text-neon' : 'chunky tone-purple'}`}>
              <span className="outline-text">{v ?? '_'}</span>
            </span>
          );
        })}
      </m.div>
      <Keyboard onKey={key} onBack={() => setFills(fills.slice(0, -1))} />
    </div>
  );
}
