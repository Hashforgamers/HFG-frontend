import { useEffect, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Keypad } from '../../ui';
import { ShapeSvg } from '../_shared/shapes';
import { flashMs, makeField, type Field } from './logic';

export default function CountObjects({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [round, setRound] = useState(0);
  const [field, setField] = useState<Field>(() => makeField(1, ctx.rng));
  const [phase, setPhase] = useState<'ready' | 'flash' | 'answer' | 'reveal'>('ready');
  const [input, setInput] = useState('');

  useEffect(() => {
    let live = true;
    const f = makeField(level, ctx.rng);
    setField(f);
    setInput('');
    (async () => {
      setPhase('ready');
      await ctx.sleep(900);
      if (!live) return;
      setPhase('flash');
      await ctx.sleep(flashMs(level));
      if (live) setPhase('answer');
    })();
    return () => {
      live = false;
    };
  }, [level, round, ctx]);

  const submit = async () => {
    if (!input) return;
    if (Number(input) === field.answer) {
      ctx.hit(30 * field.items.length);
      ctx.stat('Rounds', level);
      setLevel(level + 1);
    } else {
      ctx.miss({ life: true });
      setPhase('reveal');
      await ctx.sleep(1600);
      setRound(round + 1);
    }
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-3 pb-2">
      <div className="flex h-14 items-center gap-2">
        <p className="text-sm tracking-widest text-soft">HOW MANY</p>
        <span className="h-10 w-10"><ShapeSvg shape={field.ask} color="#ffffff" label={field.ask} /></span>
        <p className="text-sm tracking-widest text-soft">{phase === 'reveal' ? `? IT WAS ${field.answer}` : '?'}</p>
      </div>
      <div className="tray relative aspect-square w-full max-w-[min(100%,40vh)] rounded-3xl">
        {(phase === 'flash' || phase === 'reveal') &&
          field.items.map((it, i) => (
            <span key={i} className="absolute h-[11%] w-[11%] -translate-x-1/2 -translate-y-1/2" style={{ left: `${it.x * 100}%`, top: `${it.y * 100}%` }}>
              <ShapeSvg shape={it.shape} color={phase === 'reveal' && it.shape !== field.ask ? '#ffffff22' : it.color} rotate={it.rotate} />
            </span>
          ))}
        {phase === 'ready' && <p className="outline-text absolute inset-0 grid place-items-center text-3xl">Look closely…</p>}
      </div>
      {phase === 'answer' ? <Keypad value={input} onChange={setInput} onSubmit={submit} maxLength={2} /> : <div className="h-[16.5rem]" />}
    </div>
  );
}
