import { m } from 'framer-motion';
import { useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Keypad, shake } from '../../ui';
import { makeProblem } from './logic';

export default function MathBlitz({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [problem, setProblem] = useState(() => makeProblem(1, ctx.rng));
  const [input, setInput] = useState('');
  const box = useRef<HTMLDivElement>(null);

  // checks itself once as many digits as the answer has are typed
  const change = (v: string) => {
    const want = String(problem.answer);
    if (v.length < want.length) return setInput(v);
    if (v === want) {
      ctx.hit(100, 1);
      setLevel(level + 1);
      setProblem(makeProblem(level + 1, ctx.rng));
      ctx.stat('Solved', level);
    } else {
      ctx.miss({ seconds: 3 });
      if (box.current) shake(box.current);
    }
    setInput('');
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-between gap-4 pb-2">
      <div className="flex flex-1 flex-col items-center justify-center">
        <m.p key={level} initial={{ y: 10, opacity: 0 }} animate={{ y: 0, opacity: 1 }} className="text-5xl font-black tabular-nums">
          {problem.text}
        </m.p>
        <div ref={box} aria-live="polite" className="tray mt-6 grid h-16 min-w-40 place-items-center rounded-2xl px-6 text-4xl font-black tabular-nums text-neon">
          {input || <span className="text-white/25">?</span>}
        </div>
      </div>
      <Keypad value={input} onChange={change} maxLength={String(problem.answer).length} />
    </div>
  );
}
