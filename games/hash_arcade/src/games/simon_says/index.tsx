import { useEffect, useRef, useState } from 'react';
import { int } from '../../engine/rng';
import { sfx } from '../../engine/sfx';
import type { GameProps } from '../../engine/types';
import { PAD_TONES, checkInput, stepMs } from './logic';

const PADS = ['#39ff88', '#2ec5ff', '#ff4fa3', '#ffd23f'];

export default function SimonSays({ ctx }: GameProps) {
  const [sequence, setSequence] = useState<number[]>(() => [int(ctx.rng, 0, 3)]);
  const [lit, setLit] = useState<number | null>(null);
  const [turn, setTurn] = useState<'watch' | 'play'>('watch');
  const inputs = useRef<number[]>([]);

  const flashPad = (p: number, ms: number) => {
    setLit(p);
    sfx.note(PAD_TONES[p], ms / 1000);
    return ctx.sleep(ms).then(() => setLit(null));
  };

  // play the sequence back each time it grows
  useEffect(() => {
    let live = true;
    (async () => {
      setTurn('watch');
      inputs.current = [];
      await ctx.sleep(700);
      const ms = stepMs(sequence.length);
      for (const p of sequence) {
        if (!live) return;
        await flashPad(p, ms);
        await ctx.sleep(ms * 0.35);
      }
      if (live) setTurn('play');
    })();
    return () => {
      live = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [sequence]);

  const press = (p: number) => {
    if (turn !== 'play') return;
    inputs.current.push(p);
    void flashPad(p, 180);
    const result = checkInput(sequence, inputs.current);
    if (result === 'fail') {
      ctx.stat('Longest sequence', sequence.length - 1);
      ctx.miss({ life: true });
    } else if (result === 'round-done') {
      ctx.hit(10 * sequence.length);
      ctx.stat('Longest sequence', sequence.length);
      setTurn('watch');
      setSequence([...sequence, int(ctx.rng, 0, 3)]);
    }
  };

  const latest = useRef(press);
  latest.current = press;
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const p = Number(e.key) - 1;
      if (p >= 0 && p < 4) latest.current(p);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-6">
      <p aria-live="polite" className="text-sm font-bold tracking-[0.2em] text-white/60">
        {turn === 'watch' ? 'WATCH…' : `YOUR TURN · ${sequence.length} STEP${sequence.length > 1 ? 'S' : ''}`}
      </p>
      <div className="grid aspect-square w-full max-w-[min(100%,60vh)] grid-cols-2 grid-rows-2 gap-4">
        {PADS.map((c, p) => (
          <button
            key={p}
            aria-label={`Pad ${p + 1}`}
            onPointerDown={(e) => {
              e.preventDefault();
              press(p);
            }}
            onKeyDown={(e) => (e.key === 'Enter' || e.key === ' ') && press(p)}
            className="rounded-3xl transition-[opacity,box-shadow,transform] duration-100 active:scale-95"
            style={{
              background: c,
              opacity: lit === p ? 1 : 0.28,
              boxShadow: lit === p ? `0 0 40px ${c}` : 'none',
            }}
          />
        ))}
      </div>
    </div>
  );
}
