import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { shake } from '../../ui';
import { Keyboard } from '../_shared/Keyboard';
import { spellable } from '../_shared/words.helpers';
import { makeRack, wordPoints } from './logic';

export default function AnagramRush({ ctx }: GameProps) {
  const [rack] = useState(() => makeRack(ctx.rng));
  const [found, setFound] = useState<string[]>([]);
  const [typing, setTyping] = useState('');
  const [msg, setMsg] = useState('');
  const pool = rack.letters.join('');

  const enter = () => {
    const w = typing;
    setTyping('');
    if (w.length < 3) return setMsg('3 letters or more');
    if (found.includes(w)) return setMsg('Already found');
    if (!rack.answers.includes(w)) {
      setMsg('Not a word from these letters');
      const el = document.getElementById('anagram-entry');
      if (el) shake(el);
      return ctx.miss({ seconds: 2 });
    }
    setMsg('');
    setFound([w, ...found]);
    ctx.hit(wordPoints(w));
    ctx.stat('Words found', `${found.length + 1} of ${rack.answers.length}`);
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-3">
      <p className="text-sm tracking-widest text-soft">MAKE WORDS FROM THESE LETTERS · {found.length}/{rack.answers.length}</p>
      <div className="flex gap-1.5">
        {rack.letters.map((l, i) => (
          <span key={i} className="chunky tone-yellow outline-text grid h-12 w-11 place-items-center rounded-xl text-2xl uppercase">{l}</span>
        ))}
      </div>
      <div id="anagram-entry" className="tray flex h-14 w-full items-center justify-center rounded-2xl text-3xl uppercase tracking-widest text-neon">{typing || ' '}</div>
      <p className="h-4 text-sm text-danger">{msg}</p>
      <div className="no-scrollbar flex w-full flex-1 flex-wrap content-start gap-1.5 overflow-y-auto">
        {found.map((w) => <span key={w} className="chunky tone-purple outline-text rounded-xl px-2.5 py-1 text-sm uppercase">{w} +{wordPoints(w)}</span>)}
      </div>
      <Keyboard
        onKey={(l) => spellable(typing + l, pool) && setTyping(typing + l)}
        onBack={() => setTyping(typing.slice(0, -1))}
        onEnter={enter}
      />
    </div>
  );
}
