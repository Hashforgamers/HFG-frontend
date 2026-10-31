import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { shake } from '../../ui';
import { makeMirror, type Pic } from './logic';

function PicView({ pic, n, color }: { pic: Pic; n: number; color: string }) {
  return (
    <div className="grid aspect-square w-full gap-[3px]" style={{ gridTemplateColumns: `repeat(${n}, 1fr)`, gridTemplateRows: `repeat(${n}, 1fr)` }}>
      {pic.map((on, i) => <span key={i} className="rounded-[3px]" style={{ background: on ? color : 'rgb(0 0 0 / 0.25)' }} />)}
    </div>
  );
}

export default function MirrorMatch({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [round, setRound] = useState(() => makeMirror(1, ctx.rng));

  const pick = (k: number, el: HTMLElement) => {
    if (k === round.answer) {
      ctx.hit(100, 2);
      setLevel(level + 1);
      setRound(makeMirror(level + 1, ctx.rng));
    } else {
      ctx.miss({ seconds: 3 });
      shake(el);
    }
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-5">
      <p className="text-sm tracking-widest text-soft">WHICH IS ITS MIRROR IMAGE?</p>
      <div className="flex w-full items-center justify-center gap-3">
        <div className="glass w-36 rounded-2xl p-3"><PicView pic={round.pic} n={round.n} color="#ffe45c" /></div>
        <span className="text-5xl text-soft" aria-hidden>⇋</span>
        <div className="tray grid h-36 w-36 place-items-center rounded-2xl text-5xl text-soft">?</div>
      </div>
      <div className="grid w-full grid-cols-2 gap-3">
        {round.options.map((opt, k) => (
          <button key={`${level}-${k}`} aria-label={`Option ${k + 1}`} onClick={(e) => pick(k, e.currentTarget)} className="chunky tone-purple rounded-2xl p-4">
            <PicView pic={opt} n={round.n} color="#7cf06b" />
          </button>
        ))}
      </div>
    </div>
  );
}
