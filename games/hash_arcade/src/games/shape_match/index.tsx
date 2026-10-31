import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Grid, shake } from '../../ui';
import { ShapeSvg } from '../_shared/shapes';
import { makeBoard } from './logic';

export default function ShapeMatch({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [board, setBoard] = useState(() => makeBoard(1, ctx.rng));
  const [sel, setSel] = useState<number | null>(null);
  const rows = Math.ceil(board.tokens.length / board.cols);

  const tap = (i: number, el: HTMLElement) => {
    if (i >= board.tokens.length) return;
    if (sel == null || sel === i) return setSel(sel === i ? null : i);
    const pair = [sel, i].sort((a, b) => a - b);
    if (pair[0] === board.pair[0] && pair[1] === board.pair[1]) {
      ctx.hit(100, 2);
      setLevel(level + 1);
      setBoard(makeBoard(level + 1, ctx.rng));
    } else {
      ctx.miss({ seconds: 3 });
      shake(el);
    }
    setSel(null);
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-3">
      <p className="text-sm tracking-widest text-soft">TAP THE TWO THAT ARE EXACTLY THE SAME</p>
      <div className="fit-area grid w-full flex-1 place-items-center">
        <Grid
          key={level}
          cols={board.cols}
          rows={rows}
          label="Shapes"
          className="gap-2"
          onPick={tap}
          render={(i) => {
            const t = board.tokens[i];
            if (!t) return { className: 'invisible' };
            return {
              label: `${t.color} ${t.shape} turned ${t.rotate}`,
              className: `grid place-items-center rounded-2xl p-[12%] ${sel === i ? 'chunky tone-yellow' : 'tray'}`,
              content: <ShapeSvg shape={t.shape} color={t.color} rotate={t.rotate} />,
            };
          }}
        />
      </div>
    </div>
  );
}
