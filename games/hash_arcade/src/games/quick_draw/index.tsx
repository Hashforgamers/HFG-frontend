import { useEffect, useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { ROUNDS, drawPoints, makeSignals, signalGap } from './logic';

type State = 'wait' | 'decoy' | 'draw' | 'result' | 'foul';

export default function QuickDraw({ ctx }: GameProps) {
  const [round, setRound] = useState(0);
  const [retry, setRetry] = useState(0);
  const [state, setState] = useState<State>('wait');
  const [word, setWord] = useState('');
  const [ms, setMs] = useState(0);
  const drawAt = useRef(0);
  const times = useRef<number[]>([]);

  useEffect(() => {
    let live = true;
    (async () => {
      setState('wait');
      setWord('');
      for (const s of makeSignals(round, ctx.rng)) {
        await ctx.sleep(signalGap(ctx.rng));
        if (!live) return;
        setWord(s);
        if (s === 'DRAW!') {
          setState('draw');
          requestAnimationFrame(() => (drawAt.current = performance.now()));
          return;
        }
        setState('decoy');
        await ctx.sleep(550);
        if (!live) return;
        setState('wait');
        setWord('');
      }
    })();
    return () => {
      live = false;
    };
  }, [round, retry, ctx]);

  const tap = async (e: { timeStamp: number }) => {
    if (state === 'wait' || state === 'decoy') {
      setState('foul');
      ctx.miss();
      await ctx.sleep(1100);
      setRetry(retry + 1);
    } else if (state === 'draw' && drawAt.current) {
      const t = Math.round(e.timeStamp - drawAt.current);
      drawAt.current = 0;
      if (t < 100) { // too fast to be a reaction: a guess
        setState('foul');
        ctx.miss();
        await ctx.sleep(1100);
        return setRetry(retry + 1);
      }
      setMs(t);
      setState('result');
      times.current.push(t);
      ctx.hit(drawPoints(t));
      ctx.stat('Fastest draw', `${Math.min(...times.current)} ms`);
      await ctx.sleep(1100);
      if (round + 1 >= ROUNDS) ctx.finish();
      else setRound(round + 1);
    }
  };

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === ' ' || e.key === 'Enter') {
        e.preventDefault();
        void tap(e);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  });

  const bg = { wait: 'bg-[#1b1250]', decoy: 'bg-[#6a4df0]', draw: 'bg-neon', result: 'bg-volt/30', foul: 'bg-danger/70' }[state];
  const title = { wait: '…', decoy: word, draw: 'DRAW!', result: `${ms} ms`, foul: 'FOUL!' }[state];
  return (
    <div className="flex h-full flex-col gap-3">
      <p className="text-center text-sm tracking-widest text-soft">ROUND {round + 1}/{ROUNDS} · TAP ONLY ON “DRAW!”</p>
      <button
        onPointerDown={(e) => { e.preventDefault(); void tap(e); }}
        aria-live="assertive"
        className={`grid flex-1 place-items-center rounded-3xl border-[3px] border-outline ${bg}`}
      >
        <span className={`outline-text text-7xl ${state === 'draw' ? 'text-white' : 'text-white'}`}>{title}</span>
      </button>
    </div>
  );
}
