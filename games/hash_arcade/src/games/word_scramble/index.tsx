import { m } from 'framer-motion';
import { useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { shake } from '../../ui';
import { acceptScramble, makeScramble } from './logic';

export default function WordScramble({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [round, setRound] = useState(() => makeScramble(1, ctx.rng));
  const [picked, setPicked] = useState<number[]>([]);
  const slots = useRef<HTMLDivElement>(null);
  const guess = picked.map((i) => round.letters[i]).join('');

  const tap = (i: number) => {
    if (picked.includes(i)) return;
    const p = [...picked, i];
    setPicked(p);
    if (p.length < round.letters.length) return;
    const g = p.map((k) => round.letters[k]).join('');
    if (acceptScramble(round.word, g)) {
      ctx.hit(40 * g.length, 3);
      setLevel(level + 1);
      setRound(makeScramble(level + 1, ctx.rng));
    } else {
      ctx.miss({ seconds: 2 });
      if (slots.current) shake(slots.current);
    }
    setPicked([]);
  };

  const skip = () => {
    ctx.miss({ seconds: 5 });
    setRound(makeScramble(level, ctx.rng));
    setPicked([]);
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-7">
      <p className="text-sm tracking-widest text-soft">UNSCRAMBLE THE WORD</p>
      <div ref={slots} className="flex gap-1.5">
        {round.letters.map((_, k) => (
          <span key={k} className="tray grid h-14 w-11 place-items-center rounded-xl text-3xl uppercase">
            <span className="outline-text text-neon">{guess[k] ?? ''}</span>
          </span>
        ))}
      </div>
      <m.div key={level} initial={{ scale: 0.8, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="flex flex-wrap justify-center gap-2">
        {round.letters.map((l, i) => (
          <button
            key={i}
            disabled={picked.includes(i)}
            onClick={() => tap(i)}
            className="chunky tone-purple outline-text h-16 w-14 rounded-2xl text-3xl uppercase disabled:opacity-30"
          >
            {l}
          </button>
        ))}
      </m.div>
      <div className="flex gap-3">
        <button onClick={() => setPicked(picked.slice(0, -1))} className="chunky tone-purple outline-text rounded-2xl px-5 py-2">UNDO</button>
        <button onClick={skip} className="chunky tone-red outline-text rounded-2xl px-5 py-2">SKIP −5s</button>
      </div>
    </div>
  );
}
