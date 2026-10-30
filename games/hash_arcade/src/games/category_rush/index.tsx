import { m } from 'framer-motion';
import { useEffect, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { categoryFor, makePrompt } from './logic';

export default function CategoryRush({ ctx }: GameProps) {
  const [n, setN] = useState(0);
  const [category, setCategory] = useState(() => categoryFor(0, ctx.rng));
  const [prompt, setPrompt] = useState(() => makePrompt(ctx.rng, category));

  const answer = (yes: boolean) => {
    if (yes === prompt.belongs) ctx.hit(100, 1);
    else ctx.miss({ seconds: 3 });
    const c = categoryFor(n + 1, ctx.rng, category);
    setN(n + 1);
    setCategory(c);
    setPrompt(makePrompt(ctx.rng, c));
  };

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'ArrowLeft') answer(true);
      if (e.key === 'ArrowRight') answer(false);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  });

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-8">
      <m.div key={category} initial={{ scale: 0.8, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="chunky tone-yellow outline-text rounded-2xl px-6 py-2 text-2xl">
        {category.toUpperCase()}
      </m.div>
      <m.p key={n} initial={{ y: 12, opacity: 0 }} animate={{ y: 0, opacity: 1 }} className="outline-text text-6xl capitalize">{prompt.word}</m.p>
      <div className="grid w-full grid-cols-2 gap-4">
        <button onClick={() => answer(true)} className="chunky tone-green outline-text h-20 rounded-2xl text-2xl">BELONGS ←</button>
        <button onClick={() => answer(false)} className="chunky tone-red outline-text h-20 rounded-2xl text-2xl">DOESN'T →</button>
      </div>
    </div>
  );
}
