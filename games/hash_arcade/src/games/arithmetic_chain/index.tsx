import { m } from 'framer-motion';
import { useEffect, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Keypad } from '../../ui';
import { makeChain, stepMs } from './logic';

export default function ArithmeticChain({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [chain, setChain] = useState(() => makeChain(1, ctx.rng));
  const [shown, setShown] = useState(-1); // -1 = start number, then step index
  const [phase, setPhase] = useState<'watch' | 'answer' | 'reveal'>('watch');
  const [input, setInput] = useState('');

  useEffect(() => {
    let live = true;
    (async () => {
      setPhase('watch');
      for (let i = -1; i < chain.steps.length; i++) {
        if (!live) return;
        setShown(i);
        await ctx.sleep(stepMs(level));
      }
      if (live) setPhase('answer');
    })();
    return () => {
      live = false;
    };
  }, [chain, ctx, level]);

  const submit = async () => {
    if (!input || phase !== 'answer') return;
    if (Number(input) === chain.answer) {
      ctx.hit(30 * chain.steps.length);
      ctx.stat('Longest chain', chain.steps.length);
      setLevel(level + 1);
      setChain(makeChain(level + 1, ctx.rng));
    } else {
      ctx.miss({ life: true });
      setPhase('reveal');
      await ctx.sleep(1400);
      setChain(makeChain(level, ctx.rng));
    }
    setInput('');
  };

  const text = phase === 'reveal' ? `= ${chain.answer}` : phase === 'answer' ? input || '?' : shown < 0 ? String(chain.start) : chain.steps[shown];
  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-between gap-4 pb-2">
      <div className="flex flex-1 flex-col items-center justify-center gap-4">
        <p className="text-sm tracking-widest text-soft">
          {phase === 'watch' ? (shown < 0 ? 'START WITH' : `STEP ${shown + 1} OF ${chain.steps.length}`) : phase === 'answer' ? 'WHAT IS THE TOTAL?' : 'THE TOTAL WAS'}
        </p>
        <m.p key={`${phase}${shown}`} initial={{ scale: 0.6, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className={`outline-text text-7xl tabular-nums ${phase === 'reveal' ? 'text-danger' : phase === 'answer' ? 'text-neon' : 'text-white'}`}>
          {text}
        </m.p>
      </div>
      {phase === 'answer' && <Keypad value={input} onChange={setInput} onSubmit={submit} maxLength={4} />}
    </div>
  );
}
