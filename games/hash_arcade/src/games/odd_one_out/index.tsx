import { useRef, useState } from 'react';
import { makePuzzle } from '../../../../odd_one_out/src/game';
import type { GameProps } from '../../engine/types';
import { Grid, shake, useSize } from '../../ui';

const MIN_CELL = 26; // px: smallest cell that's still tappable

export default function OddOneOut({ ctx }: GameProps) {
  const areaRef = useRef<HTMLDivElement>(null);
  const { w, h } = useSize(areaRef);
  const [level, setLevel] = useState(1);
  // a new puzzle only when the level changes, not on every resize
  const [puzzle, setPuzzle] = useState<ReturnType<typeof makePuzzle> | null>(null);
  if (!puzzle && w > 0) setPuzzle(makePuzzle(1, ctx.rng, Math.floor(w / MIN_CELL), Math.floor(h / MIN_CELL)));

  const pick = (i: number, el: HTMLElement) => {
    if (!puzzle) return;
    if (i === puzzle.oddIndex) {
      ctx.hit(100, 2);
      const next = level + 1;
      setLevel(next);
      setPuzzle(makePuzzle(next, ctx.rng, Math.floor(w / MIN_CELL), Math.floor(h / MIN_CELL)));
      ctx.stat('Level reached', next);
    } else {
      ctx.miss({ seconds: 3 });
      shake(el);
    }
  };

  return (
    <div ref={areaRef} className="fit-area grid h-full place-items-center">
      {puzzle && (
        <Grid
          key={level}
          cols={puzzle.cols}
          rows={puzzle.rows}
          label={`Find the odd character, level ${level}`}
          onPick={pick}
          render={(i) => ({
            content: i === puzzle.oddIndex ? puzzle.odd : puzzle.base,
            className: 'grid place-items-center rounded-md font-mono font-extrabold leading-none text-white/90 hover:bg-white/10',
          })}
        />
      )}
    </div>
  );
}
