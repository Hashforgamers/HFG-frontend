import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { shake } from '../../ui';
import { Keyboard } from '../_shared/Keyboard';
import { judgeLink, linkPoints, startWord } from './logic';

const WHY = { 'wrong-start': 'Must start with the last letter', 'not-a-word': 'Not in the dictionary', used: 'Already used', 'too-short': '3 letters or more', ok: '' };

export default function WordChain({ ctx }: GameProps) {
  const [chain, setChain] = useState(() => [startWord(ctx.rng)]);
  const [typing, setTyping] = useState(() => chain[0].slice(-1));
  const [msg, setMsg] = useState('');
  const last = chain[chain.length - 1];

  const enter = () => {
    const v = judgeLink(last, typing, new Set(chain));
    if (v !== 'ok') {
      setMsg(WHY[v]);
      ctx.miss({ seconds: 3 });
      const el = document.getElementById('chain-entry');
      if (el) shake(el);
      return setTyping(last.slice(-1));
    }
    setMsg('');
    ctx.hit(linkPoints(typing), 4);
    ctx.stat('Chain length', chain.length);
    setChain([...chain, typing]);
    setTyping(typing.slice(-1));
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-3">
      <p className="text-sm tracking-widest text-soft">EACH WORD STARTS WITH THE LAST LETTER</p>
      <div className="no-scrollbar flex w-full flex-1 flex-wrap content-end justify-center gap-1.5 overflow-y-auto">
        {chain.map((w, i) => (
          <span key={i} className={`chunky ${i === chain.length - 1 ? 'tone-yellow' : 'tone-purple'} outline-text rounded-xl px-3 py-1 text-lg uppercase`}>
            {w.slice(0, -1)}<span className="text-neon">{w.slice(-1)}</span>
          </span>
        ))}
      </div>
      <div id="chain-entry" className="tray flex h-14 w-full items-center justify-center rounded-2xl text-3xl uppercase tracking-widest">
        <span className="text-neon">{typing[0]}</span>{typing.slice(1)}
      </div>
      <p className="h-4 text-sm text-danger">{msg}</p>
      <Keyboard
        onKey={(l) => typing.length < 7 && setTyping(typing + l)}
        onBack={() => typing.length > 1 && setTyping(typing.slice(0, -1))}
        onEnter={enter}
      />
    </div>
  );
}
