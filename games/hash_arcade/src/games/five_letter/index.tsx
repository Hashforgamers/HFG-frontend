import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { shake } from '../../ui';
import { Keyboard } from '../_shared/Keyboard';
import { isWord } from '../_shared/words.helpers';
import { TRIES, makeAnswer, markGuess, type Mark } from './logic';

const TONE: Record<Mark, string> = { hit: 'chunky tone-green', near: 'chunky tone-yellow', miss: 'bg-black/40 border-[3px] border-outline' };

export default function FiveLetter({ ctx }: GameProps) {
  const [answer, setAnswer] = useState(() => makeAnswer(ctx.rng));
  const [rows, setRows] = useState<{ word: string; marks: Mark[] }[]>([]);
  const [typing, setTyping] = useState('');
  const [msg, setMsg] = useState('');
  const [solved, setSolved] = useState(0);

  const fresh = () => {
    setAnswer(makeAnswer(ctx.rng));
    setRows([]);
    setTyping('');
  };

  const enter = async () => {
    if (typing.length < 5) return;
    if (!isWord(typing)) {
      setMsg('Not in the word list');
      const el = document.getElementById(`row-${rows.length}`);
      if (el) shake(el);
      return;
    }
    setMsg('');
    const marks = markGuess(answer, typing);
    const all = [...rows, { word: typing, marks }];
    setRows(all);
    setTyping('');
    if (typing === answer) {
      ctx.hit(100 * (TRIES - all.length + 1));
      setSolved(solved + 1);
      ctx.stat('Words solved', solved + 1);
      await ctx.sleep(1200);
      fresh();
    } else if (all.length >= TRIES) {
      setMsg(`It was ${answer.toUpperCase()}`);
      ctx.miss({ life: true });
      await ctx.sleep(1800);
      setMsg('');
      fresh();
    }
  };

  // keyboard colours: best mark seen for each letter
  const keys: Record<string, string> = {};
  for (const r of rows) [...r.word].forEach((c, i) => {
    const mk = r.marks[i];
    if (mk === 'hit' || (mk === 'near' && keys[c] !== TONE.hit) || !keys[c]) keys[c] = TONE[mk];
  });

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-2">
      <div className="flex flex-1 flex-col justify-center gap-1.5">
        {Array.from({ length: TRIES }, (_, r) => {
          const row = rows[r];
          const text = row?.word ?? (r === rows.length ? typing : '');
          return (
            <div key={r} id={`row-${r}`} className="flex gap-1.5">
              {Array.from({ length: 5 }, (_, k) => (
                <span key={k} className={`grid h-12 w-12 place-items-center rounded-lg text-2xl uppercase ${row ? TONE[row.marks[k]] : 'tray'}`}>
                  <span className="outline-text">{text[k] ?? ''}</span>
                </span>
              ))}
            </div>
          );
        })}
      </div>
      <p aria-live="polite" className="h-5 text-sm text-danger">{msg}</p>
      <Keyboard colors={keys} onKey={(l) => typing.length < 5 && setTyping(typing + l)} onBack={() => setTyping(typing.slice(0, -1))} onEnter={enter} />
    </div>
  );
}
