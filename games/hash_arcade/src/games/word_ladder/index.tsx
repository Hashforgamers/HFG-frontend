import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { shake } from '../../ui';
import { Keyboard } from '../_shared/Keyboard';
import { legalStep, makeLadder } from './logic';

export default function WordLadder({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [ladder, setLadder] = useState(() => makeLadder(1, ctx.rng));
  const [rungs, setRungs] = useState<string[]>([ladder.start]);
  const [typing, setTyping] = useState('');
  const [msg, setMsg] = useState('');
  const len = ladder.start.length;
  const last = rungs[rungs.length - 1];

  const enter = (el?: HTMLElement | null) => {
    if (typing.length < len) return;
    if (!legalStep(last, typing)) {
      setMsg(typing === last ? 'Change one letter' : [...typing].filter((c, i) => c !== last[i]).length !== 1 ? 'Change exactly one letter' : 'Not in the dictionary');
      ctx.miss();
      if (el) shake(el);
      return setTyping('');
    }
    const r = [...rungs, typing];
    setTyping('');
    setMsg('');
    if (typing !== ladder.end) return setRungs(r);
    // fewer rungs than the best route isn't possible; matching it scores most
    const extra = r.length - ladder.best.length;
    ctx.hit(Math.max(60, 80 * (ladder.best.length - 1) - extra * 30), 20);
    ctx.stat('Ladders', level);
    const next = makeLadder(level + 1, ctx.rng);
    setLevel(level + 1);
    setLadder(next);
    setRungs([next.start]);
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-3">
      <p className="text-center text-sm tracking-widest text-soft">
        <span className="outline-text text-white uppercase">{ladder.start}</span> → <span className="outline-text text-neon uppercase">{ladder.end}</span> · ONE LETTER AT A TIME · BEST {ladder.best.length - 1}
      </p>
      <div id="rungs" className="no-scrollbar flex w-full flex-1 flex-col items-center justify-end gap-1 overflow-y-auto">
        {rungs.map((w, i) => (
          <span key={i} className="flex gap-1">
            {[...w].map((c, k) => (
              <span key={k} className={`grid h-11 w-11 place-items-center rounded-lg text-2xl uppercase ${i > 0 && c !== rungs[i - 1][k] ? 'chunky tone-yellow' : 'chunky tone-purple'}`}>
                <span className="outline-text">{c}</span>
              </span>
            ))}
          </span>
        ))}
        <span className="flex gap-1">
          {Array.from({ length: len }, (_, k) => (
            <span key={k} className="tray grid h-11 w-11 place-items-center rounded-lg text-2xl uppercase text-neon">{typing[k] ?? ''}</span>
          ))}
        </span>
        <p className="h-5 text-sm text-danger">{msg}</p>
      </div>
      <div className="flex gap-3">
        <button disabled={rungs.length < 2} onClick={() => setRungs(rungs.slice(0, -1))} className="chunky tone-purple outline-text rounded-2xl px-4 py-1.5 text-sm disabled:opacity-40">UNDO RUNG</button>
        <button onClick={() => { ctx.miss({ seconds: 10 }); const nx = makeLadder(level, ctx.rng); setLadder(nx); setRungs([nx.start]); setTyping(''); }} className="chunky tone-red outline-text rounded-2xl px-4 py-1.5 text-sm">SKIP −10s</button>
      </div>
      <Keyboard
        onKey={(l) => typing.length < len && setTyping(typing + l)}
        onBack={() => setTyping(typing.slice(0, -1))}
        onEnter={() => enter(document.getElementById('rungs'))}
      />
    </div>
  );
}
