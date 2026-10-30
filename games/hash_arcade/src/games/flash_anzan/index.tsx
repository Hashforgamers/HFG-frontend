import { m } from 'framer-motion';
import { useEffect, useState } from 'react';
import { sfx } from '../../engine/sfx';
import type { GameProps } from '../../engine/types';
import { Keypad } from '../../ui';
import { makeAnzan } from './logic';

export default function FlashAnzan({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [round, setRound] = useState(0);
  const [anzan, setAnzan] = useState(() => makeAnzan(1, ctx.rng));
  const [flash, setFlash] = useState<{ i: number; v: number } | null>(null);
  const [phase, setPhase] = useState<'flash' | 'answer' | 'reveal'>('flash');
  const [input, setInput] = useState('');
  const sum = anzan.numbers.reduce((a, b) => a + b, 0);

  useEffect(() => {
    let live = true;
    const a = makeAnzan(level, ctx.rng);
    setAnzan(a);
    setInput('');
    setPhase('flash');
    (async () => {
      await ctx.sleep(700);
      for (let i = 0; i < a.numbers.length; i++) {
        if (!live) return;
        setFlash({ i, v: a.numbers[i] });
        sfx.tick();
        await ctx.sleep(a.ms * 0.75);
        setFlash(null);
        await ctx.sleep(a.ms * 0.25);
      }
      if (live) setPhase('answer');
    })();
    return () => {
      live = false;
    };
  }, [level, round, ctx]);

  const submit = async () => {
    if (!input) return;
    if (Number(input) === sum) {
      ctx.hit(25 * anzan.numbers.length);
      ctx.stat('Most numbers', anzan.numbers.length);
      setLevel(level + 1);
    } else {
      ctx.miss({ life: true });
      setPhase('reveal');
      await ctx.sleep(1400);
      setRound(round + 1);
    }
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-between gap-4 pb-2">
      <div className="flex flex-1 flex-col items-center justify-center gap-4">
        <p className="text-sm tracking-widest text-soft">
          {phase === 'flash' ? `ADD ${anzan.numbers.length} NUMBERS IN YOUR HEAD` : phase === 'answer' ? 'WHAT IS THE SUM?' : 'THE SUM WAS'}
        </p>
        <div className="tray grid h-40 w-full max-w-xs place-items-center rounded-3xl">
          {phase === 'flash' && flash && (
            <m.span key={flash.i} initial={{ scale: 0.7 }} animate={{ scale: 1 }} className="outline-text text-8xl tabular-nums text-volt">{flash.v}</m.span>
          )}
          {phase === 'answer' && <span className="outline-text text-6xl tabular-nums text-neon">{input || '?'}</span>}
          {phase === 'reveal' && <span className="outline-text text-6xl tabular-nums text-danger">{sum}</span>}
        </div>
      </div>
      {phase === 'answer' && <Keypad value={input} onChange={setInput} onSubmit={submit} maxLength={5} />}
    </div>
  );
}
