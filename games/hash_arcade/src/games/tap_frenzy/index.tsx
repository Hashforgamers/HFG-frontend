import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Dot, Field } from '../_shared/field';
import { ON_SCREEN, SIZE, bubble, type Bubble } from './logic';

export default function TapFrenzy({ ctx }: GameProps) {
  const [bubbles, setBubbles] = useState<Bubble[]>(() => {
    const b: Bubble[] = [];
    while (b.length < ON_SCREEN) b.push(bubble(ctx.rng, b));
    return b;
  });

  const tap = (x: number, y: number) => {
    const hitB = bubbles.find((b) => Math.hypot(b.x - x, b.y - y) <= SIZE / 2);
    if (!hitB) return;
    ctx.hit(hitB.gold ? 30 : 10);
    const rest = bubbles.filter((b) => b !== hitB);
    setBubbles([...rest, bubble(ctx.rng, rest)]);
  };

  return (
    <div className="flex h-full flex-col items-center justify-center gap-4">
      <p className="text-sm tracking-widest text-soft">POP AS MANY AS YOU CAN · GOLD = ×3</p>
      <Field label="Pop the bubbles" onTap={tap}>
        {bubbles.map((b) => (
          <Dot key={b.id} x={b.x} y={b.y} d={SIZE} tone={b.gold ? 'tone-yellow' : 'tone-purple'}>{b.gold ? '★' : ''}</Dot>
        ))}
      </Field>
    </div>
  );
}
