import { m } from 'framer-motion';
import { useEffect, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Keypad } from '../../ui';
import { START_LENGTH, makeDigits, showMs } from './logic';

export default function NumberRecall({ ctx }: GameProps) {
  const [length, setLength] = useState(START_LENGTH);
  const [round, setRound] = useState(0);
  const [digits, setDigits] = useState('');
  const [phase, setPhase] = useState<'show' | 'type' | 'reveal'>('show');
  const [input, setInput] = useState('');

  useEffect(() => {
    let live = true;
    const d = makeDigits(length, ctx.rng);
    setDigits(d);
    setInput('');
    setPhase('show');
    ctx.sleep(showMs(length)).then(() => live && setPhase('type'));
    return () => {
      live = false;
    };
  }, [length, round, ctx]);

  // checks itself once every digit is in
  const change = async (v: string) => {
    setInput(v);
    if (v.length < digits.length) return;
    if (v === digits) {
      ctx.hit(20 * length);
      ctx.stat('Longest number', length);
      setLength(length + 1);
    } else {
      ctx.miss({ life: true });
      setPhase('reveal');
      await ctx.sleep(1500);
      setRound(round + 1);
    }
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-between gap-4 pb-2">
      <div className="flex flex-1 flex-col items-center justify-center gap-5">
        <p className="text-sm tracking-widest text-soft">{phase === 'show' ? `REMEMBER ${length} DIGITS` : phase === 'type' ? 'TYPE THEM BACK' : 'IT WAS'}</p>
        <m.p key={phase + round + length} initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="outline-text break-all text-center font-mono text-5xl tracking-[0.15em]">
          {phase === 'type' ? <span className="text-neon">{input.padEnd(digits.length, '·')}</span> : <span className={phase === 'reveal' ? 'text-danger' : ''}>{digits}</span>}
        </m.p>
      </div>
      {phase === 'type' && <Keypad value={input} onChange={change} maxLength={digits.length} />}
    </div>
  );
}
