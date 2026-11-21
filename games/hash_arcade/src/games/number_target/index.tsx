import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Combine } from '../_shared/Combine';
import { combine, makeTarget } from './logic';

export default function NumberTarget({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [round, setRound] = useState(() => makeTarget(1, ctx.rng));
  const [steps, setSteps] = useState(0);

  const next = (l: number) => {
    setLevel(l);
    setRound(makeTarget(l, ctx.rng));
    setSteps(0);
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-6">
      <p className="text-lg tracking-widest text-soft">REACH THE TARGET</p>
      <p className="outline-text -mt-4 text-7xl tabular-nums text-volt">{round.target}</p>
      <p className="-mt-4 text-xs text-soft">Whole numbers only · you don't have to use them all</p>
      <Combine<number>
        key={round.nums.join() + round.target}
        start={round.nums}
        combine={combine}
        label={String}
        onReset={() => setSteps(0)}
        onMerge={(cards) => {
          setSteps(steps + 1);
          if (cards.some((c) => c.value === round.target)) {
            // fewer steps, more points
            ctx.hit(150 + Math.max(0, 6 - steps) * 25, 15);
            ctx.stat('Targets hit', level);
            next(level + 1);
          } else if (cards.length === 1) ctx.miss({ seconds: 3 });
        }}
      />
      <button onClick={() => { ctx.miss({ seconds: 10 }); next(level); }} className="text-sm text-soft underline">
        Skip this target (−10s)
      </button>
    </div>
  );
}
