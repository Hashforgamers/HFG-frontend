import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Grid } from '../../ui';
import { isSolved, shuffled, sizeFor, slidable, slide } from './logic';

export default function SlidingPuzzle({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [board, setBoard] = useState(() => shuffled(1, ctx.rng));
  const [moves, setMoves] = useState(0);
  const n = sizeFor(level);

  const tap = async (i: number) => {
    if (!slidable(board, n, i)) return;
    const b = slide(board, n, i);
    setBoard(b);
    setMoves(moves + 1);
    if (isSolved(b)) {
      ctx.hit(Math.max(100, 400 * (n - 2) - moves * 2), 40);
      ctx.stat('Solved', level);
      await ctx.sleep(500);
      setLevel(level + 1);
      setBoard(shuffled(level + 1, ctx.rng));
      setMoves(0);
    }
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-3">
      <p className="text-sm tracking-widest text-soft">PUT 1–{n * n - 1} IN ORDER · {moves} MOVES</p>
      <div className="fit-area grid w-full flex-1 place-items-center">
        <Grid
          key={level}
          cols={n}
          rows={n}
          label="Sliding tiles"
          className="gap-2"
          onPick={tap}
          render={(i) => ({
            label: board[i] ? `Tile ${board[i]}` : 'Gap',
            className: board[i] ? `chunky ${board[i] === i + 1 ? 'tone-green' : 'tone-purple'} grid place-items-center rounded-2xl` : 'bg-black/20 rounded-2xl',
            content: board[i] ? <span className="outline-text text-[0.6em]">{board[i]}</span> : null,
          })}
        />
      </div>
    </div>
  );
}
