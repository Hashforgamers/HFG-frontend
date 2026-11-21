import { useEffect, useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { gapFor, hitsPlayer, lanesFor, makeRow, speedFor } from './logic';

interface Row {
  id: number;
  y: number;
  blocked: number[];
}

export default function DodgeRush({ ctx }: GameProps) {
  const [lane, setLane] = useState(1);
  const laneRef = useRef(1);
  const rows = useRef<Row[]>([]);
  const passed = useRef(0);
  const field = useRef<HTMLDivElement>(null);
  const [, redraw] = useState(0);
  const lanes = lanesFor(passed.current);

  // obstacles fall on the engine clock; one free lane per row is guaranteed
  useEffect(() => {
    let last = ctx.now();
    let nextId = 0;
    return ctx.onFrame((t) => {
      const dt = (t - last) / 1000;
      last = t;
      const level = passed.current;
      const L = lanesFor(level);
      if (laneRef.current >= L) laneRef.current = L - 1;
      const top = rows.current[rows.current.length - 1];
      if (!top || top.y > gapFor(level)) rows.current.push({ id: nextId++, y: -0.1, blocked: makeRow(L, level, ctx.rng) });
      for (const r of rows.current) r.y += speedFor(level) * dt;
      for (const r of [...rows.current]) {
        if (hitsPlayer(r.y, r.blocked, laneRef.current)) {
          ctx.miss({ life: true });
          rows.current = rows.current.filter((x) => x !== r);
        } else if (r.y > 1) {
          rows.current = rows.current.filter((x) => x !== r);
          passed.current++;
          ctx.hit(10);
          ctx.stat('Rows dodged', passed.current);
        }
      }
      redraw(t);
    });
  }, [ctx]);

  const move = (d: number) => {
    const n = Math.max(0, Math.min(lanesFor(passed.current) - 1, laneRef.current + d));
    laneRef.current = n;
    setLane(n);
  };

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'ArrowLeft') move(-1);
      if (e.key === 'ArrowRight') move(1);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  });

  const w = 100 / lanes;
  return (
    <div className="flex h-full flex-col items-center justify-center gap-3">
      <p className="text-sm tracking-widest text-soft">TAP LEFT OR RIGHT HALF TO SWITCH LANES</p>
      <div
        ref={field}
        role="application"
        aria-label={`Lane ${lane + 1} of ${lanes}`}
        onPointerDown={(e) => {
          e.preventDefault();
          const box = e.currentTarget.getBoundingClientRect();
          move(e.clientX - box.left < box.width / 2 ? -1 : 1);
        }}
        className="tray relative aspect-[3/4] w-full max-w-[min(100%,48vh)] touch-none overflow-hidden rounded-3xl"
      >
        {Array.from({ length: lanes - 1 }, (_, i) => (
          <span key={i} className="absolute inset-y-0 w-px bg-white/10" style={{ left: `${(i + 1) * w}%` }} />
        ))}
        {rows.current.flatMap((r) =>
          r.blocked.map((b) => (
            <span key={`${r.id}-${b}`} className="chunky tone-red absolute rounded-xl" style={{ left: `${b * w + 2}%`, width: `${w - 4}%`, top: `${r.y * 100}%`, height: '8%' }} />
          )),
        )}
        <span className="chunky tone-green outline-text absolute grid place-items-center rounded-2xl text-2xl transition-[left] duration-100" style={{ left: `${lane * w + w * 0.2}%`, width: `${w * 0.6}%`, top: '85%', height: '10%' }}>
          ▲
        </span>
      </div>
    </div>
  );
}
