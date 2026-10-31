import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { shake } from '../../ui';
import { ShapeSvg } from '../_shared/shapes';
import { makeScene, type Item } from './logic';

export default function SpotDifference({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [scene, setScene] = useState(() => makeScene(1, ctx.rng));
  const [found, setFound] = useState<number[]>([]);

  const tap = async (i: number, el: HTMLElement) => {
    if (found.includes(i)) return;
    if (!scene.diffs.includes(i)) {
      ctx.miss({ seconds: 2 });
      return shake(el);
    }
    const f = [...found, i];
    setFound(f);
    ctx.hit(80);
    if (f.length === scene.diffs.length) {
      ctx.hit(100 * level, 10);
      ctx.stat('Scenes cleared', level);
      await ctx.sleep(500);
      setLevel(level + 1);
      setScene(makeScene(level + 1, ctx.rng));
      setFound([]);
    }
  };

  const board = (items: Item[], side: string) => (
    <div className="glass grid aspect-square w-full gap-1 rounded-2xl p-2" style={{ gridTemplateColumns: `repeat(${scene.cols}, 1fr)`, gridTemplateRows: `repeat(${scene.rows}, 1fr)` }}>
      {items.map((it, i) => (
        <button
          key={i}
          aria-label={`${side} ${i + 1}`}
          onPointerDown={(e) => { e.preventDefault(); void tap(i, e.currentTarget); }}
          className={`relative grid place-items-center rounded-lg p-1 ${found.includes(i) ? 'ring-4 ring-volt' : ''}`}
        >
          {it && <ShapeSvg shape={it.shape} color={it.color} />}
        </button>
      ))}
    </div>
  );

  return (
    <div className="mx-auto flex h-full max-w-[min(100%,46vh)] flex-col items-center justify-center gap-2">
      <p className="text-sm tracking-widest text-soft">FIND {scene.diffs.length - found.length} MORE DIFFERENCE{scene.diffs.length - found.length === 1 ? '' : 'S'}</p>
      {board(scene.left, 'Top picture, cell')}
      {board(scene.right, 'Bottom picture, cell')}
    </div>
  );
}
