import { m } from 'framer-motion';
import { useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Keypad, shake } from '../../ui';
import { makeSequence } from './logic';

export default function NumberSequence({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [seq, setSeq] = useState(() => makeSequence(1, ctx.rng));
  const [input, setInput] = useState('');
  const [reveal, setReveal] = useState<number | null>(null);
  const row = useRef<HTMLDivElement>(null);

  const next = () => {
    setLevel(level + 1);
    setSeq(makeSequence(level + 1, ctx.rng));
    setInput('');
  };

  const submit = async () => {
    if (!input || reveal != null) return;
    if (Number(input) === seq.full[seq.missing]) {
      ctx.hit(150, 2);
      next();
    } else {
      // a wrong answer shows the right one, then moves on so nobody gets stuck
      ctx.miss({ seconds: 5 });
      if (row.current) shake(row.current);
      setReveal(seq.full[seq.missing]);
      await ctx.sleep(900);
      setReveal(null);
      next();
    }
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-between gap-4 pb-2">
      <div className="flex flex-1 flex-col items-center justify-center gap-6">
        <p className="text-sm font-bold tracking-[0.25em] text-white/50">FIND THE MISSING TERM</p>
        <m.div key={level} ref={row} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} className="flex flex-wrap justify-center gap-2">
          {seq.full.map((v, i) => (
            <span
              key={i}
              className={`grid h-14 min-w-12 place-items-center rounded-xl px-2 text-xl font-black tabular-nums ${
                i === seq.missing ? (reveal != null ? 'bg-danger/20 text-danger' : 'border-[3px] border-dashed border-neon text-neon') : 'glass'
              }`}
            >
              {i === seq.missing ? (reveal ?? (input || '?')) : v}
            </span>
          ))}
        </m.div>
      </div>
      <Keypad value={input} onChange={setInput} onSubmit={submit} maxLength={4} />
    </div>
  );
}
