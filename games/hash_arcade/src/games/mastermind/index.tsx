import { useState } from 'react';
import type { GameProps } from '../../engine/types';
import { PEGS, TRIES, colorsFor, makeCode, score } from './logic';

const COLORS = ['#ff6f61', '#7cf06b', '#2e9bff', '#ffe45c', '#ff77ae', '#ffffff'];

export default function Mastermind({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [code, setCode] = useState(() => makeCode(1, ctx.rng));
  const [rows, setRows] = useState<{ guess: number[]; exact: number; near: number }[]>([]);
  const [guess, setGuess] = useState<number[]>([]);
  const [reveal, setReveal] = useState(false);
  const colors = colorsFor(level);

  const fresh = (l: number) => {
    setLevel(l);
    setCode(makeCode(l, ctx.rng));
    setRows([]);
    setGuess([]);
    setReveal(false);
  };

  const submit = async () => {
    if (guess.length < PEGS) return;
    const s = score(code, guess);
    const all = [...rows, { guess, ...s }];
    setRows(all);
    setGuess([]);
    if (s.exact === PEGS) {
      ctx.hit(60 * (TRIES - all.length + 1));
      ctx.stat('Codes cracked', level);
      await ctx.sleep(700);
      fresh(level + 1);
    } else if (all.length >= TRIES) {
      setReveal(true);
      ctx.miss({ life: true });
      await ctx.sleep(1800);
      fresh(level);
    }
  };

  const peg = (c: number | undefined, k: number) => (
    <span key={k} className="h-8 w-8 rounded-full border-[3px] border-outline" style={{ background: c == null ? 'rgb(0 0 0 / 0.25)' : COLORS[c] }} />
  );
  return (
    <div className="mx-auto flex h-full max-w-md flex-col gap-3">
      <div className="flex items-center justify-between">
        <p className="text-sm tracking-widest text-soft">CRACK THE {PEGS}-COLOUR CODE</p>
        <p className="text-sm text-soft">● right place · ○ wrong place</p>
      </div>
      <div className="no-scrollbar tray flex-1 space-y-1.5 overflow-y-auto rounded-2xl p-2">
        {rows.map((r, i) => (
          <div key={i} className="flex items-center justify-between rounded-xl bg-black/20 px-2 py-1">
            <span className="flex gap-1.5">{r.guess.map(peg)}</span>
            <span aria-label={`${r.exact} right place, ${r.near} wrong place`} className="text-lg tracking-widest">
              <span className="text-neon">{'●'.repeat(r.exact)}</span><span className="text-white">{'○'.repeat(r.near)}</span>
            </span>
          </div>
        ))}
        {reveal && <div className="flex items-center gap-2 px-2 py-1 text-danger">CODE: <span className="flex gap-1.5">{code.map(peg)}</span></div>}
      </div>
      <div className="flex items-center justify-between">
        <span className="flex gap-1.5">{Array.from({ length: PEGS }, (_, k) => peg(guess[k], k))}</span>
        <span className="text-sm text-soft">{TRIES - rows.length} tries left</span>
      </div>
      <div className="flex flex-wrap gap-2">
        {COLORS.slice(0, colors).map((c, k) => (
          <button key={k} aria-label={`Colour ${k + 1}`} onClick={() => guess.length < PEGS && setGuess([...guess, k])} className="h-12 w-12 rounded-full border-[3px] border-outline shadow-[inset_0_-4px_0_rgb(0_0_0/0.3)]" style={{ background: c }} />
        ))}
        <button onClick={() => setGuess(guess.slice(0, -1))} aria-label="Delete" className="chunky tone-red outline-text h-12 w-12 rounded-2xl">⌫</button>
        <button onClick={submit} disabled={guess.length < PEGS} className="chunky tone-green outline-text h-12 flex-1 rounded-2xl disabled:opacity-40">GUESS</button>
      </div>
    </div>
  );
}
