import { m } from 'framer-motion';
import { useEffect, useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { shake } from '../../ui';
import { correctSide, makePair } from './logic';

export default function GreaterSmaller({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [pair, setPair] = useState(() => makePair(1, ctx.rng));
  const refs = { left: useRef<HTMLButtonElement>(null), right: useRef<HTMLButtonElement>(null) };

  const choose = (side: 'left' | 'right') => {
    if (side === correctSide(pair)) {
      ctx.hit(100, 1);
      setLevel(level + 1);
      setPair(makePair(level + 1, ctx.rng));
    } else {
      ctx.miss({ seconds: 3 });
      const el = refs[side].current;
      if (el) shake(el);
    }
  };

  const latest = useRef(choose);
  latest.current = choose;
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'ArrowLeft') latest.current('left');
      if (e.key === 'ArrowRight') latest.current('right');
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  const greater = pair.ask === 'greater';
  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-8">
      <m.p
        key={`${level}-${pair.ask}`}
        initial={{ scale: 0.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        className={`text-3xl font-black tracking-wider ${greater ? 'text-neon outline-text' : 'text-volt outline-text'}`}
      >
        TAP THE {greater ? 'GREATER ▲' : 'SMALLER ▼'}
      </m.p>
      <div className="grid w-full grid-cols-2 gap-4">
        {(['left', 'right'] as const).map((side) => (
          <button
            key={side}
            ref={refs[side]}
            onPointerDown={(e) => {
              e.preventDefault();
              choose(side);
            }}
            onKeyDown={(e) => (e.key === 'Enter' || e.key === ' ') && choose(side)}
            className="chunky tone-purple outline-text grid aspect-[4/5] place-items-center rounded-3xl text-5xl tabular-nums"
          >
            {pair[side].label}
          </button>
        ))}
      </div>
    </div>
  );
}
