import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Grid } from '../../ui';
import { GLYPHS, GLYPH_COLORS } from '../_shared/glyphs';
import { layoutFor, makeDeck } from './logic';

export default function CardPairs({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [deck, setDeck] = useState(() => makeDeck(1, ctx.rng));
  const [open, setOpen] = useState<number[]>([]);
  const [matched, setMatched] = useState<Set<number>>(new Set());
  const [busy, setBusy] = useState(false);
  const { cols, rows } = layoutFor(level);

  const flip = async (i: number) => {
    if (busy || open.includes(i) || matched.has(i)) return;
    const now = [...open, i];
    setOpen(now);
    if (now.length < 2) return;
    const [a, b] = now;
    if (deck[a] === deck[b]) {
      const m = new Set(matched).add(a).add(b);
      setMatched(m);
      setOpen([]);
      ctx.hit(60);
      if (m.size === deck.length) {
        ctx.hit(150 * level, 15); // board cleared
        ctx.stat('Boards cleared', level);
        setBusy(true);
        await ctx.sleep(500);
        setLevel(level + 1);
        setDeck(makeDeck(level + 1, ctx.rng));
        setMatched(new Set());
        setBusy(false);
      }
    } else {
      setBusy(true);
      ctx.miss();
      await ctx.sleep(700);
      setOpen([]);
      setBusy(false);
    }
  };

  return (
    <div className="fit-area grid h-full place-items-center">
      <Grid
        key={level}
        cols={cols}
        rows={rows}
        label="Cards"
        className="gap-2.5"
        onPick={flip}
        render={(i) => {
          const up = open.includes(i) || matched.has(i);
          const g = deck[i];
          return {
            label: up ? GLYPHS[g] : 'Face-down card',
            className: `grid place-items-center rounded-2xl ${up ? 'chunky tone-yellow' : 'chunky tone-purple'} ${matched.has(i) ? 'opacity-50' : ''}`,
            content: up ? (
              <span className="outline-text text-[0.75em]" style={{ color: GLYPH_COLORS[g % GLYPH_COLORS.length] }}>{GLYPHS[g]}</span>
            ) : (
              <span className="text-[0.5em] text-white/40">#</span>
            ),
          };
        }}
      />
    </div>
  );
}
