import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Grid, shake } from '../../ui';
import { makeSymbolHunt } from './logic';

export default function SymbolHunt({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [hunt, setHunt] = useState(() => makeSymbolHunt(1, ctx.rng));
  const [found, setFound] = useState<number[]>([]);

  const tap = (i: number, el: HTMLElement) => {
    if (found.includes(i)) return;
    if (!hunt.targets.includes(i)) {
      ctx.miss({ seconds: 2 });
      return shake(el);
    }
    const f = [...found, i];
    ctx.hit(60);
    if (f.length === hunt.targets.length) {
      ctx.hit(40 * f.length, 3);
      setLevel(level + 1);
      setHunt(makeSymbolHunt(level + 1, ctx.rng));
      setFound([]);
    } else setFound(f);
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-3">
      <div className="flex items-center gap-3">
        <p className="text-sm tracking-widest text-soft">TAP EVERY</p>
        <span className="chunky tone-yellow outline-text grid h-14 w-14 place-items-center rounded-2xl text-4xl">{hunt.target}</span>
        <p className="text-sm tracking-widest text-soft">{found.length}/{hunt.targets.length}</p>
      </div>
      <div className="fit-area grid w-full flex-1 place-items-center">
        <Grid
          key={level}
          cols={hunt.size}
          rows={hunt.size}
          label={`Find every ${hunt.target}`}
          className="gap-1.5"
          onPick={tap}
          render={(i) => ({
            content: <span className="text-[0.7em] text-white">{hunt.cells[i]}</span>,
            className: `grid place-items-center rounded-xl ${found.includes(i) ? 'chunky tone-green' : 'tray'}`,
          })}
        />
      </div>
    </div>
  );
}
