import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { Keyboard } from '../_shared/Keyboard';
import { nextWord, wpm } from './logic';

export default function TypingSprint({ ctx }: GameProps) {
  const [queue, setQueue] = useState(() => [nextWord(0, ctx.rng), nextWord(0, ctx.rng), nextWord(0, ctx.rng)]);
  const [typed, setTyped] = useState('');
  const [done, setDone] = useState(0);
  const [chars, setChars] = useState(0);
  const [wrongKey, setWrongKey] = useState(false);
  const word = queue[0];

  // every correct letter advances; a wrong one is refused and breaks the combo
  const key = (l: string) => {
    if (word[typed.length] !== l) {
      setWrongKey(true);
      return ctx.miss();
    }
    setWrongKey(false);
    const t = typed + l;
    if (t.length < word.length) return setTyped(t);
    const c = chars + word.length + 1;
    ctx.hit(10 * word.length);
    ctx.stat('Speed', `${wpm(c, ctx.now())} WPM`);
    setChars(c);
    setDone(done + 1);
    setQueue([...queue.slice(1), nextWord(done + 1, ctx.rng)]);
    setTyped('');
  };

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-4">
      <p className="text-sm tracking-widest text-soft">TYPE EACH WORD · {done} DONE · {wpm(chars, ctx.now())} WPM</p>
      <div className="flex flex-1 flex-col items-center justify-center gap-4">
        <p className={`outline-text font-mono text-5xl tracking-wider ${wrongKey ? 'shake' : ''}`}>
          <span className="text-neon">{typed}</span>
          <span className="text-white">{word.slice(typed.length)}</span>
        </p>
        <p className="text-xl text-soft">{queue.slice(1).join('  ')}</p>
      </div>
      {/* wrong letters are never accepted, so there is nothing to delete */}
      <Keyboard onKey={key} onBack={() => {}} />
    </div>
  );
}
