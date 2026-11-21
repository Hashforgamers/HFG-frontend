import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { shake } from '../../ui';
import { GAMES, PEOPLE, SNACKS, clueText, makeLogic } from './logic';

export default function LogicGrid({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [p, setP] = useState(() => makeLogic(1, ctx.rng));
  const [game, setGame] = useState<(number | null)[]>(() => Array(p.n).fill(null));
  const [snack, setSnack] = useState<(number | null)[]>(() => Array(p.n).fill(null));

  const check = (el: HTMLElement) => {
    if (game.some((v) => v == null) || snack.some((v) => v == null)) return shake(el);
    if (game.every((g, i) => g === p.solution.game[i]) && snack.every((s, i) => s === p.solution.snack[i])) {
      ctx.hit(150 * p.n, 45);
      ctx.stat('Puzzles', level);
      const next = makeLogic(level + 1, ctx.rng);
      setLevel(level + 1);
      setP(next);
      setGame(Array(next.n).fill(null));
      setSnack(Array(next.n).fill(null));
    } else {
      ctx.miss({ seconds: 10 });
      shake(el);
    }
  };

  // tapping cycles through the options; each option only once per column
  const cycle = (arr: (number | null)[], set: (v: (number | null)[]) => void, i: number) => {
    let v = arr[i] == null ? 0 : arr[i]! + 1;
    while (v < p.n && arr.some((x, j) => j !== i && x === v)) v++;
    set(arr.map((x, j) => (j === i ? (v < p.n ? v : null) : x)));
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col gap-3">
      <ul className="glass space-y-1.5 rounded-2xl p-3 text-[15px]">
        {p.clues.map((c, i) => <li key={i} className="flex gap-2"><span className="text-volt">{i + 1}.</span>{clueText(c)}</li>)}
      </ul>
      <div className="grid gap-2" style={{ gridTemplateColumns: 'auto 1fr 1fr' }}>
        <span /><span className="text-center text-xs tracking-widest text-soft">PLAYS</span><span className="text-center text-xs tracking-widest text-soft">EATS</span>
        {PEOPLE.slice(0, p.n).map((name, i) => (
          <div key={name} className="contents">
            <span className="outline-text self-center pr-2 text-xl">{name}</span>
            <button onClick={() => cycle(game, setGame, i)} className={`chunky ${game[i] == null ? 'tone-purple' : 'tone-green'} outline-text h-12 rounded-2xl`}>{game[i] == null ? 'tap' : GAMES[game[i]!]}</button>
            <button onClick={() => cycle(snack, setSnack, i)} className={`chunky ${snack[i] == null ? 'tone-purple' : 'tone-yellow'} outline-text h-12 rounded-2xl`}>{snack[i] == null ? 'tap' : SNACKS[snack[i]!]}</button>
          </div>
        ))}
      </div>
      <button onClick={(e) => check(e.currentTarget)} className="chunky tone-green outline-text mt-auto h-14 rounded-2xl text-xl">CHECK</button>
    </div>
  );
}
