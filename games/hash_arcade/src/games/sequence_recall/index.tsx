import { useEffect, useRef, useState } from 'react';
import { sfx } from '../../engine/sfx';
import type { GameProps } from '../../engine/types';
import { shake } from '../../ui';
import { makeRecall } from './logic';

export default function SequenceRecall({ ctx }: GameProps) {
  const [length, setLength] = useState(3);
  const [round, setRound] = useState(0);
  const [recall, setRecall] = useState(() => makeRecall(3, ctx.rng));
  const [showing, setShowing] = useState<string | null>(null);
  const [turn, setTurn] = useState<'watch' | 'play'>('watch');
  const [got, setGot] = useState(0);
  const pad = useRef<HTMLDivElement>(null);

  useEffect(() => {
    let live = true;
    const r = makeRecall(length, ctx.rng);
    setRecall(r);
    setGot(0);
    setTurn('watch');
    (async () => {
      await ctx.sleep(600);
      for (const s of r.sequence) {
        if (!live) return;
        setShowing(s);
        sfx.note(440, 0.1);
        await ctx.sleep(750);
        setShowing(null);
        await ctx.sleep(200);
      }
      if (live) setTurn('play');
    })();
    return () => {
      live = false;
    };
  }, [length, round, ctx]);

  const press = (s: string) => {
    if (turn !== 'play') return;
    if (s !== recall.sequence[got]) {
      ctx.miss({ life: true });
      if (pad.current) shake(pad.current);
      setRound(round + 1);
      return;
    }
    sfx.note(520 + got * 30, 0.08);
    if (got + 1 === recall.sequence.length) {
      ctx.hit(15 * length);
      ctx.stat('Longest sequence', length);
      setLength(length + 1);
    } else setGot(got + 1);
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-8">
      <p className="text-sm tracking-widest text-soft">{turn === 'watch' ? 'WATCH THE ORDER' : `TAP THEM IN ORDER · ${got}/${length}`}</p>
      <div className="tray grid h-36 w-36 place-items-center rounded-3xl">
        <span className="outline-text text-8xl text-volt">{turn === 'watch' ? showing ?? '' : '?'}</span>
      </div>
      <div ref={pad} className="grid grid-cols-3 gap-3">
        {recall.pad.map((s) => (
          <button key={s} disabled={turn !== 'play'} onClick={() => press(s)} className="chunky tone-purple outline-text h-20 w-20 rounded-2xl text-4xl disabled:opacity-50">
            {s}
          </button>
        ))}
      </div>
    </div>
  );
}
