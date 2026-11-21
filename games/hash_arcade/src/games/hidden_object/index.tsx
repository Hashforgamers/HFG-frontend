import { useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { isOnTarget, makeScene } from './logic';

export default function HiddenObject({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [scene, setScene] = useState(() => makeScene(1, ctx.rng));
  const field = useRef<HTMLDivElement>(null);

  const tap = (e: React.PointerEvent) => {
    e.preventDefault();
    const box = field.current!.getBoundingClientRect();
    const x = (e.clientX - box.left) / box.width;
    const y = (e.clientY - box.top) / box.height;
    if (isOnTarget(scene, x, y)) {
      ctx.hit(100, 3);
      setLevel(level + 1);
      setScene(makeScene(level + 1, ctx.rng));
    } else ctx.miss({ seconds: 2 });
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-3">
      <div className="flex items-center gap-3">
        <p className="text-sm tracking-widest text-soft">FIND THE ONE</p>
        <span className="chunky tone-yellow outline-text grid h-14 w-14 place-items-center rounded-2xl text-4xl">{scene.target.glyph}</span>
      </div>
      <div
        ref={field}
        onPointerDown={tap}
        role="application"
        aria-label={`Crowded scene. Find the ${scene.target.glyph}`}
        className="tray relative aspect-square w-full max-w-[min(100%,58vh)] cursor-crosshair overflow-hidden rounded-3xl"
        style={{ containerType: 'inline-size' }}
      >
        {[...scene.clutter, scene.target].map((t, i) => (
          <span
            key={`${level}-${i}`}
            aria-hidden
            className="pointer-events-none absolute -translate-x-1/2 -translate-y-1/2 leading-none"
            style={{ left: `${t.x * 100}%`, top: `${t.y * 100}%`, color: t.color, fontSize: `${t.size * 100}cqw`, transform: `translate(-50%, -50%) rotate(${t.rotate}deg)` }}
          >
            {t.glyph}
          </span>
        ))}
      </div>
    </div>
  );
}
