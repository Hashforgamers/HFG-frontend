import { useEffect, useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Dot, Field } from '../_shared/field';
import { RADIUS, countFor, mover, step, type Mover } from './logic';

export default function MovingTarget({ ctx }: GameProps) {
  const level = useRef(1);
  const movers = useRef<Mover[]>([mover(1, ctx.rng)]);
  const [, redraw] = useState(0);

  useEffect(() => {
    let last = ctx.now();
    return ctx.onFrame((t) => {
      const dt = (t - last) / 1000;
      last = t;
      movers.current = movers.current.map((m) => step(m, dt));
      while (movers.current.length < countFor(level.current)) movers.current.push(mover(level.current, ctx.rng));
      redraw(t);
    });
  }, [ctx]);

  const tap = (x: number, y: number) => {
    const m = movers.current.find((o) => Math.hypot(o.x - x, o.y - y) <= RADIUS * 1.2);
    if (!m) return ctx.miss();
    ctx.hit(100);
    level.current++;
    ctx.stat('Hits', level.current - 1);
    movers.current = [...movers.current.filter((o) => o !== m), mover(level.current, ctx.rng)];
  };

  return (
    <div className="flex h-full flex-col items-center justify-center gap-4">
      <p className="text-sm tracking-widest text-soft">HIT THE MOVING TARGETS</p>
      <Field label="Moving targets" onTap={tap}>
        {movers.current.map((m) => <Dot key={m.id} x={m.x} y={m.y} d={RADIUS * 2} tone="tone-yellow">◎</Dot>)}
      </Field>
    </div>
  );
}
