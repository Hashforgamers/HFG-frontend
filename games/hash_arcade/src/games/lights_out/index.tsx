import { useState } from 'react';
import { sfx } from '../../engine/sfx';
import type { GameProps } from '../../engine/types';
import { Button, Grid } from '../../ui';
import { press, scramble, solved, solvePoints } from './logic';

export default function LightsOut({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [board, setBoard] = useState(() => scramble(1, ctx.rng));
  const [grid, setGrid] = useState(board.grid);
  const [moves, setMoves] = useState(0);

  const tap = (i: number) => {
    const g = press(grid, i, board.n);
    sfx.note(440 + (i % board.n) * 40, 0.08);
    if (!solved(g)) {
      setGrid(g);
      setMoves(moves + 1);
      return;
    }
    ctx.hit(solvePoints(board.presses.length, moves + 1), 15);
    ctx.stat('Boards cleared', level);
    const next = scramble(level + 1, ctx.rng);
    setLevel(level + 1);
    setBoard(next);
    setGrid(next.grid);
    setMoves(0);
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-4">
      <p className="text-sm font-bold tracking-[0.2em] text-white/60">
        BOARD {level} · {moves} MOVE{moves === 1 ? '' : 'S'} · PAR {board.presses.length}
      </p>
      <div className="fit-area grid w-full flex-1 place-items-center">
        <Grid
          key={level}
          cols={board.n}
          rows={board.n}
          label="Lights grid"
          className="gap-2"
          onPick={tap}
          render={(i) => ({
            label: grid[i] ? 'On' : 'Off',
            className: `rounded-2xl transition-colors duration-150 ${grid[i] ? 'chunky tone-yellow' : 'tray'}`,
          })}
        />
      </div>
      <Button variant="ghost" className="px-6 text-sm" onClick={() => { setGrid(board.grid); setMoves(0); }}>
        RESET BOARD
      </Button>
    </div>
  );
}
