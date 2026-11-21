import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Grid, shake } from '../../ui';
import { canStep, makeMaze, walk } from './logic';

export default function MathMaze({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [maze, setMaze] = useState(() => makeMaze(1, ctx.rng));
  const [path, setPath] = useState([0]);
  const { n } = maze;
  const total = walk(maze, path);
  const end = n * n - 1;

  const tap = (i: number, el: HTMLElement) => {
    const last = path[path.length - 1];
    if (!canStep(last, i, n)) return shake(el);
    const p = [...path, i];
    setPath(p);
    if (i !== end) return;
    if (walk(maze, p) === maze.target) {
      ctx.hit(60 * n, 8);
      ctx.stat('Mazes solved', level);
      setLevel(level + 1);
      setMaze(makeMaze(level + 1, ctx.rng));
      setPath([0]);
    } else {
      ctx.miss({ seconds: 3 });
      setPath([0]);
    }
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-3">
      <div className="flex w-full items-center justify-around">
        <p className="text-center text-sm text-soft">START<span className="outline-text block text-3xl text-white">{maze.start}</span></p>
        <p className="text-center text-sm text-soft">NOW<span className="outline-text block text-4xl text-volt">{total}</span></p>
        <p className="text-center text-sm text-soft">TARGET<span className="outline-text block text-3xl text-neon">{maze.target}</span></p>
      </div>
      <p className="text-xs text-soft">Move right or down from the top-left to the bottom-right corner.</p>
      <div className="fit-area grid w-full flex-1 place-items-center">
        <Grid
          key={level}
          cols={n}
          rows={n}
          label="Maze"
          className="gap-2"
          onPick={tap}
          render={(i) => {
            const on = path.includes(i);
            const next = canStep(path[path.length - 1], i, n);
            const s = maze.cells[i];
            return {
              content: <span className="outline-text text-[0.55em]">{s.op}{s.v}</span>,
              label: `${s.op}${s.v}${on ? ', on your path' : ''}`,
              className: `grid place-items-center rounded-xl ${on ? 'chunky tone-green' : next ? 'chunky tone-purple' : 'tray opacity-60'} ${i === end ? 'ring-4 ring-volt' : ''}`,
            };
          }}
        />
      </div>
      <div className="flex gap-3">
        <button disabled={path.length < 2} onClick={() => setPath(path.slice(0, -1))} className="chunky tone-purple outline-text rounded-2xl px-5 py-2 disabled:opacity-40">UNDO</button>
        <button onClick={() => setPath([0])} className="chunky tone-purple outline-text rounded-2xl px-5 py-2">RESTART</button>
      </div>
    </div>
  );
}
