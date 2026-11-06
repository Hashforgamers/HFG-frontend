import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Grid, shake } from '../../ui';
import { isAnswer, makeTask } from './logic';

export default function VisualRush({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [task, setTask] = useState(() => makeTask(1, ctx.rng));

  const tap = (i: number, el: HTMLElement) => {
    if (isAnswer(task, i)) {
      ctx.hit(100, 1.5);
      setLevel(level + 1);
      setTask(makeTask(level + 1, ctx.rng, task.kind));
    } else {
      ctx.miss({ seconds: 2 });
      shake(el);
    }
  };

  const prompt = task.kind === 'odd-colour' ? 'TAP THE DIFFERENT COLOUR' : task.kind === 'odd-char' ? 'TAP THE DIFFERENT CHARACTER' : `FIND ${task.target}`;
  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-3">
      <p className="outline-text text-xl tracking-wider text-volt">{prompt}</p>
      <div className="fit-area grid w-full flex-1 place-items-center">
        <Grid
          key={level}
          cols={task.size}
          rows={task.size}
          label={prompt}
          className="gap-1.5"
          onPick={tap}
          render={(i) => {
            if (task.kind === 'odd-colour') return { className: 'rounded-xl border-[3px] border-outline', style: { background: i === task.at ? task.odd : task.base } };
            if (task.kind === 'odd-char') return { className: 'tray grid place-items-center rounded-xl font-mono', content: <span className="text-[0.6em]">{i === task.at ? task.odd : task.base}</span> };
            return { className: 'chunky tone-purple grid place-items-center rounded-xl', content: <span className="outline-text text-[0.5em]">{task.cells[i]}</span> };
          }}
        />
      </div>
    </div>
  );
}
