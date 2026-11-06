import { useEffect, useRef, useState } from 'react';
import { useSession } from '../../engine/run';
import type { GameProps } from '../../engine/types';
import { ANTICIPATION_MS, TRIES, average, trialPoints, waitMs } from './logic';

type State = 'wait' | 'go' | 'foul' | 'result';

export default function ReactionTimer({ ctx }: GameProps) {
  const [state, setState] = useState<State>('wait');
  const [times, setTimes] = useState<number[]>([]);
  const [trial, setTrial] = useState(0); // bumps to restart a try
  const cueAt = useRef(0);
  const paused = useSession((s) => s.status === 'paused');

  // a pause mid-try voids it: the timing would be meaningless
  useEffect(() => {
    if (paused && (state === 'wait' || state === 'go')) setTrial((t) => t + 1);
  }, [paused, state]);

  useEffect(() => {
    let live = true;
    setState('wait');
    ctx.sleep(waitMs(ctx.rng())).then(() => {
      if (!live) return;
      setState('go');
      // timestamp the first frame the green is actually on screen
      requestAnimationFrame(() => (cueAt.current = performance.now()));
    });
    return () => {
      live = false;
    };
  }, [trial, ctx]);

  const tap = async (e: { timeStamp: number }) => {
    const guessed = state === 'go' && cueAt.current > 0 && e.timeStamp - cueAt.current < ANTICIPATION_MS;
    if (state === 'wait' || guessed) {
      cueAt.current = 0;
      setState('foul');
      ctx.miss();
      await ctx.sleep(1000);
      setTrial((t) => t + 1);
    } else if (state === 'go' && cueAt.current) {
      const ms = Math.max(1, Math.round(e.timeStamp - cueAt.current));
      cueAt.current = 0;
      const all = [...times, ms];
      setTimes(all);
      setState('result');
      ctx.hit(trialPoints(ms));
      ctx.stat('Average', `${average(all)} ms`);
      ctx.stat('Fastest', `${Math.min(...all)} ms`);
      await ctx.sleep(1100);
      if (all.length >= TRIES) ctx.finish();
      else setTrial((t) => t + 1);
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

  const look = {
    wait: { bg: 'bg-danger/80', title: 'WAIT…', sub: 'Tap when it turns green' },
    go: { bg: 'bg-neon', title: 'TAP!', sub: '' },
    foul: { bg: 'bg-white/10', title: 'TOO EARLY', sub: 'False start — this try is redone' },
    result: { bg: 'bg-volt/30', title: `${times[times.length - 1] ?? 0} ms`, sub: `+${trialPoints(times[times.length - 1] ?? 999)} pts` },
  }[state];

  return (
    <div className="flex h-full flex-col gap-3">
      <button
        onPointerDown={(e) => {
          e.preventDefault();
          void tap(e);
        }}
        aria-live="assertive"
        className={`grid flex-1 place-items-center rounded-3xl transition-colors duration-75 ${look.bg} ${state === 'go' ? 'text-ink' : 'text-white'}`}
      >
        <span>
          <span className="block text-5xl font-black">{look.title}</span>
          <span className="mt-2 block text-sm font-bold opacity-80">{look.sub}</span>
        </span>
      </button>
      <div className="flex justify-center gap-2" aria-label={`Try ${Math.min(times.length + 1, TRIES)} of ${TRIES}`}>
        {Array.from({ length: TRIES }, (_, i) => (
          <span key={i} className={`h-3 w-8 rounded-full border-2 border-outline ${i < times.length ? 'bg-neon' : 'bg-white/15'}`} />
        ))}
      </div>
    </div>
  );
}
