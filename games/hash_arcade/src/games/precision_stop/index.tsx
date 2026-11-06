import { useEffect, useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { judge, makeZone, triangle } from './logic';

export default function PrecisionStop({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [zone, setZone] = useState(() => makeZone(1, ctx.rng));
  const [verdict, setVerdict] = useState<string | null>(null);
  const marker = useRef<HTMLDivElement>(null);
  const pos = useRef(0);
  const stopped = useRef(false);
  const startAt = useRef(0);

  // the marker moves on the engine's frame clock, so pausing freezes it
  useEffect(() => {
    stopped.current = false;
    startAt.current = ctx.now();
    const phase0 = ctx.rng();
    return ctx.onFrame((t) => {
      if (stopped.current) return;
      pos.current = triangle(phase0 + ((t - startAt.current) / 1000) * zone.speed);
      if (marker.current) marker.current.style.left = `${pos.current * 100}%`;
    });
  }, [zone, ctx]);

  const stop = async () => {
    if (stopped.current) return;
    stopped.current = true;
    const j = judge(pos.current, zone);
    if (j.inZone) {
      ctx.hit(j.points);
      setVerdict(j.perfect ? 'PERFECT!' : 'NICE');
      ctx.stat('Rounds cleared', level);
    } else {
      ctx.miss({ life: true });
      setVerdict('MISS');
    }
    await ctx.sleep(650);
    setVerdict(null);
    const next = j.inZone ? level + 1 : level;
    setLevel(next);
    setZone(makeZone(next, ctx.rng));
  };

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === ' ' || e.key === 'Enter') {
        e.preventDefault();
        void stop();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  });

  return (
    <button
      onPointerDown={(e) => {
        e.preventDefault();
        void stop();
      }}
      aria-label="Stop the marker"
      className="flex h-full w-full flex-col items-center justify-center gap-10 px-2"
    >
      <p aria-live="polite" className={`h-10 text-3xl font-black ${verdict === 'MISS' ? 'text-danger' : 'text-neon outline-text'}`}>
        {verdict ?? ''}
      </p>
      <div className="tray relative h-16 w-full max-w-lg rounded-2xl">
        <div
          className="absolute inset-y-0 rounded-xl bg-neon/25 ring-2 ring-neon"
          style={{ left: `${(zone.center - zone.width / 2) * 100}%`, width: `${zone.width * 100}%` }}
        >
          <div className="absolute inset-y-2 left-1/2 w-px bg-neon/70" />
        </div>
        <div ref={marker} className="absolute -inset-y-2 w-1.5 -translate-x-1/2 rounded-full bg-white shadow-[0_0_14px_white]" />
      </div>
      <p className="text-sm font-bold tracking-[0.2em] text-white/50">TAP ANYWHERE TO STOP</p>
    </button>
  );
}
