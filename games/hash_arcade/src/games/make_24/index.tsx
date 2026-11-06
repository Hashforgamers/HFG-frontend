import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Combine } from '../_shared/Combine';
import { apply, eq, q, show, type Q } from '../_shared/fraction';
import { TARGET, make24 } from './logic';

export default function Make24({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [hand, setHand] = useState(() => make24(1, ctx.rng));

  const next = (solved: boolean) => {
    const l = solved ? level + 1 : level;
    setLevel(l);
    setHand(make24(l, ctx.rng));
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-6">
      <p className="text-lg tracking-widest text-soft">USE ALL FOUR TO MAKE</p>
      <p className="outline-text -mt-4 text-7xl text-volt">24</p>
      <Combine<Q>
        key={hand.join() + level}
        start={hand.map((n) => q(n))}
        combine={apply}
        label={show}
        onMerge={(cards) => {
          if (cards.length > 1) return;
          if (eq(cards[0].value, TARGET)) {
            ctx.hit(250, 20);
            ctx.stat('Solved', level);
            next(true);
          } else ctx.miss({ seconds: 5 });
        }}
      />
      <button onClick={() => { ctx.miss({ seconds: 10 }); next(false); }} className="text-sm text-soft underline">
        Skip this hand (−10s)
      </button>
    </div>
  );
}
