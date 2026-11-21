import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { shake } from '../../ui';
import { canMove, disksFor, done, moveDisk, optimal, solvePoints, start } from './logic';

const DISK = ['tone-red', 'tone-yellow', 'tone-green', 'tone-purple', 'tone-red', 'tone-yellow', 'tone-green'];

export default function Hanoi({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const n = disksFor(level);
  const [pegs, setPegs] = useState(() => start(disksFor(1)));
  const [from, setFrom] = useState<number | null>(null);
  const [moves, setMoves] = useState(0);

  const tap = async (k: number, el: HTMLElement) => {
    if (from == null) return pegs[k].length && setFrom(k);
    if (from === k) return setFrom(null);
    if (!canMove(pegs, from, k)) {
      shake(el);
      ctx.miss();
      return setFrom(null);
    }
    const p = moveDisk(pegs, from, k);
    setPegs(p);
    setFrom(null);
    setMoves(moves + 1);
    if (done(p, n)) {
      ctx.hit(solvePoints(n, moves + 1), 30);
      ctx.stat('Towers moved', level);
      await ctx.sleep(600);
      setLevel(level + 1);
      setPegs(start(disksFor(level + 1)));
      setMoves(0);
    }
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-5">
      <p className="text-center text-sm tracking-widest text-soft">MOVE THE TOWER TO THE RIGHT PEG · NEVER BIG ON SMALL</p>
      <p className="text-sm text-soft">{moves} moves · best {optimal(n)}</p>
      <div className="grid w-full grid-cols-3 gap-2">
        {pegs.map((stack, k) => (
          <button
            key={k}
            onClick={(e) => tap(k, e.currentTarget)}
            aria-label={`Peg ${k + 1}, ${stack.length} disks${from === k ? ', selected' : ''}`}
            className={`relative flex h-64 flex-col-reverse items-center justify-start gap-1 rounded-2xl pb-3 ${from === k ? 'bg-volt/20' : 'tray'}`}
          >
            <span className="absolute bottom-3 top-6 w-2 rounded-full bg-black/40" />
            {stack.map((d, j) => (
              <span
                key={d}
                className={`chunky ${DISK[d - 1]} relative h-6 rounded-lg ${from === k && j === stack.length - 1 ? '-translate-y-3' : ''}`}
                style={{ width: `${30 + (d / 7) * 65}%` }}
              />
            ))}
          </button>
        ))}
      </div>
    </div>
  );
}
