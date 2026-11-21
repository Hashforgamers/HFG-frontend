import { m } from 'framer-motion';
import { useEffect, useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { shake } from '../../ui';
import { hexOf, makeRound, type ColorName } from './logic';

export default function ColorClash({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [round, setRound] = useState(() => makeRound(1, ctx.rng));
  const btns = useRef<(HTMLButtonElement | null)[]>([]);

  const answer = (name: ColorName, i: number) => {
    if (name === round.ink) {
      ctx.hit(100, 1);
      setLevel(level + 1);
      setRound(makeRound(level + 1, ctx.rng));
    } else {
      ctx.miss({ seconds: 2 });
      const el = btns.current[i];
      if (el) shake(el);
    }
  };

  const latest = useRef(answer);
  latest.current = answer;
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const i = Number(e.key) - 1;
      if (i >= 0 && i < round.options.length) latest.current(round.options[i], i);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [round]);

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-10">
      <p className="text-sm font-bold tracking-[0.25em] text-white/50">TAP THE INK COLOUR</p>
      <m.div
        key={level}
        initial={{ scale: 0.7, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        className="outline-text text-6xl tracking-tight sm:text-7xl"
        style={{ color: hexOf(round.ink) }}
        aria-label={`The word ${round.word} in ${round.ink.toLowerCase()} ink`}
      >
        {round.word}
      </m.div>
      <div className={`grid w-full gap-3 ${round.options.length > 4 ? 'grid-cols-3' : 'grid-cols-2'}`}>
        {round.options.map((name, i) => (
          <button
            key={name}
            ref={(el) => (btns.current[i] = el)}
            onPointerDown={(e) => {
              e.preventDefault();
              answer(name, i);
            }}
            onKeyDown={(e) => (e.key === 'Enter' || e.key === ' ') && answer(name, i)}
            className="chunky tone-purple outline-text h-16 rounded-2xl text-xl tracking-wider"
          >
            {name}
          </button>
        ))}
      </div>
    </div>
  );
}
