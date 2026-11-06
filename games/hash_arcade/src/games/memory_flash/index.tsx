import { useEffect, useState } from 'react';
import { sfx } from '../../engine/sfx';
import type { GameProps } from '../../engine/types';
import { Grid, shake } from '../../ui';
import { makeFlash, showMs, type Flash } from './logic';

type Phase = 'ready' | 'show' | 'input';

export default function MemoryFlash({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [flash, setFlash] = useState<Flash>(() => makeFlash(1, ctx.rng));
  const [phase, setPhase] = useState<Phase>('ready');
  const [found, setFound] = useState<number[]>([]);

  // each round: short beat, show the pattern, hide it, wait for taps
  useEffect(() => {
    let live = true;
    (async () => {
      setPhase('ready');
      await ctx.sleep(500);
      if (!live) return;
      setPhase('show');
      await ctx.sleep(showMs(flash.cells.length));
      if (live) setPhase('input');
    })();
    return () => {
      live = false;
    };
  }, [flash, ctx]);

  const pick = (i: number, el: HTMLElement) => {
    if (phase !== 'input' || found.includes(i)) return;
    if (!flash.cells.includes(i)) {
      ctx.miss({ life: true });
      shake(el);
      setFound([]);
      setFlash(makeFlash(level, ctx.rng)); // same level, fresh pattern
      return;
    }
    sfx.note(392 + found.length * 40, 0.12);
    const now = [...found, i];
    setFound(now);
    if (now.length === flash.cells.length) {
      ctx.hit(50 * flash.cells.length);
      ctx.stat('Round', level + 1);
      setFound([]);
      setLevel(level + 1);
      setFlash(makeFlash(level + 1, ctx.rng));
    }
  };

  const msg = { ready: 'Get ready…', show: 'Remember these', input: `Tap all ${flash.cells.length}` }[phase];
  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-4">
      <p aria-live="polite" className="text-sm font-bold tracking-[0.2em] text-white/60">{msg.toUpperCase()}</p>
      <div className="fit-area grid w-full flex-1 place-items-center">
        <Grid
          key={`${level}-${flash.cells.join()}`}
          cols={flash.size}
          rows={flash.size}
          label={`Memory grid, ${flash.size} by ${flash.size}`}
          className="gap-2"
          onPick={pick}
          render={(i) => {
            const lit = (phase === 'show' && flash.cells.includes(i)) || found.includes(i);
            return {
              label: found.includes(i) ? 'Found' : 'Cell',
              className: `rounded-xl transition-colors duration-150 ${lit ? 'chunky tone-green' : 'tray'}`,
            };
          }}
        />
      </div>
    </div>
  );
}
