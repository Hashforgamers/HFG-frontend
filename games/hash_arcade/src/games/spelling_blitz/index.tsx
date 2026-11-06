import { m } from 'framer-motion';
import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { shake } from '../../ui';
import { makeSpell } from './logic';

export default function SpellingBlitz({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [q, setQ] = useState(() => makeSpell(1, ctx.rng));

  const pick = (o: string, el: HTMLElement) => {
    if (o === q.word) {
      ctx.hit(100, 1);
      setLevel(level + 1);
      setQ(makeSpell(level + 1, ctx.rng));
    } else {
      ctx.miss({ seconds: 3 });
      shake(el);
    }
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-8">
      <p className="text-sm tracking-widest text-soft">TAP THE CORRECT SPELLING</p>
      <m.div key={level} initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} className="flex w-full flex-col gap-3">
        {q.options.map((o) => (
          <button key={o} onClick={(e) => pick(o, e.currentTarget)} className="chunky tone-purple outline-text h-16 rounded-2xl text-3xl lowercase tracking-wide">
            {o}
          </button>
        ))}
      </m.div>
    </div>
  );
}
