import { useEffect, useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { shake } from '../../ui';
import { HOLES, gapMs, nextPop, upMs, type Pop } from './logic';

export default function WhackMole({ ctx }: GameProps) {
  const [pop, setPop] = useState<Pop | null>(null);
  const [whacked, setWhacked] = useState(false);
  const level = useRef(1);
  const hitThis = useRef(false);

  // one mole (or decoy) at a time; an escaped mole breaks the combo
  useEffect(() => {
    let live = true;
    (async () => {
      let last = -1;
      while (live) {
        await ctx.sleep(gapMs(level.current));
        if (!live) return;
        const p = nextPop(level.current, ctx.rng, last);
        last = p.hole;
        hitThis.current = false;
        setWhacked(false);
        setPop(p);
        await ctx.sleep(upMs(level.current));
        if (!live) return;
        if (!p.decoy && !hitThis.current) ctx.miss();
        setPop(null);
      }
    })();
    return () => {
      live = false;
    };
  }, [ctx]);

  const whack = (h: number, el: HTMLElement) => {
    if (!pop || pop.hole !== h || hitThis.current) return;
    hitThis.current = true;
    setWhacked(true);
    if (pop.decoy) {
      ctx.miss({ seconds: 3 });
      shake(el);
    } else {
      ctx.hit(100);
      level.current++;
    }
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-6">
      <p className="text-sm tracking-widest text-soft">WHACK THE MOLES · NOT THE BOMBS (−3s)</p>
      <div className="grid w-full grid-cols-3 gap-4">
        {Array.from({ length: HOLES }, (_, h) => {
          const up = pop?.hole === h;
          return (
            <button
              key={h}
              aria-label={up ? (pop!.decoy ? 'Bomb' : 'Mole') : `Hole ${h + 1}`}
              onPointerDown={(e) => { e.preventDefault(); whack(h, e.currentTarget); }}
              className="tray relative grid aspect-square place-items-end justify-center overflow-hidden rounded-full"
            >
              <span
                className={`chunky ${up && pop!.decoy ? 'tone-red' : 'tone-yellow'} outline-text mb-[8%] grid h-[70%] w-[70%] place-items-center rounded-full text-4xl transition-transform duration-100`}
                style={{ transform: up && !whacked ? 'translateY(0)' : 'translateY(110%)' }}
              >
                {up && pop!.decoy ? '✖' : '◕'}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
