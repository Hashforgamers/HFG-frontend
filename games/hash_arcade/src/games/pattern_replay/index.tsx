import { useEffect, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Button, Grid } from '../../ui';
import { cycle, makePattern, samePattern, showMs, type Pattern } from './logic';

const TONES = ['', 'tone-green', 'tone-yellow', 'tone-red'];

export default function PatternReplay({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [round, setRound] = useState(0);
  const [p, setP] = useState<Pattern>(() => makePattern(1, ctx.rng));
  const [mine, setMine] = useState<number[]>([]);
  const [phase, setPhase] = useState<'show' | 'build' | 'reveal'>('show');

  useEffect(() => {
    let live = true;
    const next = makePattern(level, ctx.rng);
    setP(next);
    setMine(Array(next.cells.length).fill(0));
    setPhase('show');
    ctx.sleep(showMs(next)).then(() => live && setPhase('build'));
    return () => {
      live = false;
    };
  }, [level, round, ctx]);

  const done = async () => {
    if (samePattern(p.cells, mine)) {
      ctx.hit(15 * p.cells.filter(Boolean).length * p.colors);
      ctx.stat('Patterns', level);
      setLevel(level + 1);
    } else {
      ctx.miss({ life: true });
      setPhase('reveal');
      await ctx.sleep(1600);
      setRound(round + 1);
    }
  };

  const show = phase === 'build' ? mine : p.cells;
  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-4">
      <p className="text-sm tracking-widest text-soft">
        {phase === 'show' ? 'REMEMBER THE PATTERN' : phase === 'build' ? (p.colors > 1 ? 'TAP TO CYCLE COLOURS' : 'TAP TO REBUILD IT') : 'IT WAS THIS'}
      </p>
      <div className="fit-area grid w-full flex-1 place-items-center">
        <Grid
          key={`${level}-${round}`}
          cols={p.size}
          rows={p.size}
          label="Pattern"
          className="gap-2"
          onPick={(i) => phase === 'build' && setMine(mine.map((v, k) => (k === i ? cycle(v, p.colors) : v)))}
          render={(i) => ({
            label: show[i] ? `Colour ${show[i]}` : 'Off',
            className: `rounded-xl ${show[i] ? `chunky ${TONES[show[i]]}` : 'tray'}`,
          })}
        />
      </div>
      {phase === 'build' && <Button onClick={done} className="w-full max-w-xs text-xl">DONE</Button>}
    </div>
  );
}
