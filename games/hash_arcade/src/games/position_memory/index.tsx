import { useEffect, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Grid, shake } from '../../ui';
import { GLYPH_COLORS } from '../_shared/glyphs';
import { makePlacement, showMs, type Placement } from './logic';

export default function PositionMemory({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [round, setRound] = useState(0);
  const [p, setP] = useState<Placement>(() => makePlacement(1, ctx.rng));
  const [phase, setPhase] = useState<'show' | 'ask'>('show');
  const [asked, setAsked] = useState(0);

  useEffect(() => {
    let live = true;
    const next = makePlacement(level, ctx.rng);
    setP(next);
    setAsked(0);
    setPhase('show');
    ctx.sleep(showMs(next.items.length)).then(() => live && setPhase('ask'));
    return () => {
      live = false;
    };
  }, [level, round, ctx]);

  const want = p.items[p.order[asked]];
  const tap = (i: number, el: HTMLElement) => {
    if (phase !== 'ask') return;
    if (i !== want.cell) {
      ctx.miss({ life: true });
      shake(el);
      setRound(round + 1);
      return;
    }
    if (asked + 1 === p.items.length) {
      ctx.hit(40 * p.items.length);
      ctx.stat('Most items', p.items.length);
      setLevel(level + 1);
    } else setAsked(asked + 1);
  };

  const found = new Set(p.order.slice(0, asked).map((k) => p.items[k].cell));
  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-4">
      <div className="flex h-20 items-center gap-3">
        {phase === 'show' ? (
          <p className="text-sm tracking-widest text-soft">REMEMBER WHERE EACH ONE IS</p>
        ) : (
          <>
            <p className="text-sm tracking-widest text-soft">WHERE WAS</p>
            <span className="chunky tone-yellow outline-text grid h-16 w-16 place-items-center rounded-2xl text-4xl">{want.glyph}</span>
          </>
        )}
      </div>
      <div className="fit-area grid w-full flex-1 place-items-center">
        <Grid
          key={`${level}-${round}`}
          cols={p.size}
          rows={p.size}
          label="Positions"
          className="gap-2"
          onPick={tap}
          render={(i) => {
            const item = p.items.find((it) => it.cell === i);
            const visible = item && (phase === 'show' || found.has(i));
            return {
              label: visible ? item.glyph : 'Cell',
              className: `grid place-items-center rounded-xl ${visible ? 'chunky tone-purple' : 'tray'}`,
              content: visible ? (
                <span className="outline-text text-[0.6em]" style={{ color: GLYPH_COLORS[p.items.indexOf(item) % GLYPH_COLORS.length] }}>{item.glyph}</span>
              ) : null,
            };
          }}
        />
      </div>
    </div>
  );
}
