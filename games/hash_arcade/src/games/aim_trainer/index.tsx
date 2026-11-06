import { useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Dot, Field } from '../_shared/field';
import { TARGETS, hitPoints, place, sizeFor } from './logic';

export default function AimTrainer({ ctx }: GameProps) {
  const [n, setN] = useState(0);
  const [target, setTarget] = useState(() => place(0, ctx.rng));
  const shownAt = useRef(ctx.now());
  const times = useRef<number[]>([]);

  const tap = (x: number, y: number) => {
    const r = sizeFor(n) / 2;
    if (Math.hypot(x - target.x, y - target.y) > r * 1.15) return ctx.miss(); // small grace ring for fingers
    const ms = ctx.now() - shownAt.current;
    times.current.push(ms);
    ctx.hit(hitPoints(ms));
    ctx.stat('Average', `${Math.round(times.current.reduce((a, b) => a + b, 0) / times.current.length)} ms`);
    if (n + 1 >= TARGETS) return ctx.finish();
    setN(n + 1);
    setTarget(place(n + 1, ctx.rng, target));
    shownAt.current = ctx.now();
  };

  return (
    <div className="flex h-full flex-col items-center justify-center gap-4">
      <p className="text-sm tracking-widest text-soft">TARGET {n + 1} OF {TARGETS} · ACCURACY COUNTS</p>
      <Field label="Hit the target" onTap={tap}>
        <Dot x={target.x} y={target.y} d={sizeFor(n)} tone="tone-red" style={{ boxShadow: 'inset 0 0 0 4px #fff, inset 0 0 0 8px #e8392c' }} />
      </Field>
    </div>
  );
}
