import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Grid, shake } from '../../ui';
import { makeHunt } from './logic';

export default function FindNumber({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [hunt, setHunt] = useState(() => makeHunt(1, ctx.rng));

  const tap = (i: number, el: HTMLElement) => {
    if (hunt.cells[i] === hunt.target) {
      ctx.hit(100, 1.5);
      setLevel(level + 1);
      setHunt(makeHunt(level + 1, ctx.rng));
    } else {
      ctx.miss({ seconds: 2 });
      shake(el);
    }
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-3">
      <div className="flex items-center gap-3">
        <p className="text-sm tracking-widest text-soft">FIND</p>
        <span className="chunky tone-yellow outline-text rounded-2xl px-5 py-1 text-4xl tabular-nums">{hunt.target}</span>
      </div>
      <div className="fit-area grid w-full flex-1 place-items-center">
        <Grid
          key={level}
          cols={hunt.size}
          rows={hunt.size}
          label={`Find ${hunt.target}`}
          className="gap-1.5"
          onPick={tap}
          render={(i) => ({
            content: <span className="outline-text text-[0.55em] tabular-nums">{hunt.cells[i]}</span>,
            className: 'chunky tone-purple grid place-items-center rounded-xl',
          })}
        />
      </div>
    </div>
  );
}
