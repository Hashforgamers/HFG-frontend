import { useEffect, useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Dot, Field } from '../_shared/field';
import { lifetimeMs, sizeFor, spawn, within } from './logic';

export default function ReflexRush({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [target, setTarget] = useState(() => spawn(1, ctx.rng));
  const born = useRef(ctx.now());
  const dot = useRef<HTMLDivElement>(null);

  // the target shrinks as its time runs out; escaping costs a life
  useEffect(() => {
    born.current = ctx.now();
    return ctx.onFrame((t) => {
      const left = 1 - (t - born.current) / lifetimeMs(level);
      if (dot.current) dot.current.style.transform = `translate(-50%, -50%) scale(${Math.max(0, left)})`;
      if (left <= 0) {
        ctx.miss({ life: true });
        born.current = t;
        setTarget(spawn(level, ctx.rng));
      }
    });
  }, [target, level, ctx]);

  const tap = (x: number, y: number) => {
    const d = sizeFor(level);
    if (!within(x, y, target, d / 2)) return;
    ctx.hit(100);
    ctx.stat('Targets', level);
    setLevel(level + 1);
    setTarget(spawn(level + 1, ctx.rng));
  };

  return (
    <div className="flex h-full flex-col items-center justify-center gap-4">
      <p className="text-sm tracking-widest text-soft">TAP BEFORE IT SHRINKS AWAY</p>
      <Field label="Tap the target" onTap={tap}>
        <div ref={dot} className="pointer-events-none absolute" style={{ left: `${target.x * 100}%`, top: `${target.y * 100}%`, width: `${sizeFor(level) * 100}%`, height: `${sizeFor(level) * 100}%` }}>
          <Dot x={0.5} y={0.5} d={1} tone="tone-green" />
        </div>
      </Field>
    </div>
  );
}
