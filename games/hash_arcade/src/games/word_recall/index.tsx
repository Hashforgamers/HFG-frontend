import { m } from 'framer-motion';
import { useEffect, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { makeWordRound, studyMs, type WordRound } from './logic';

export default function WordRecall({ ctx }: GameProps) {
  const [level, setLevel] = useState(1);
  const [w, setW] = useState<WordRound>(() => makeWordRound(1, ctx.rng));
  const [phase, setPhase] = useState<'study' | 'test'>('study');
  const [at, setAt] = useState(0);

  useEffect(() => {
    let live = true;
    const r = makeWordRound(level, ctx.rng);
    setW(r);
    setAt(0);
    setPhase('study');
    ctx.sleep(studyMs(r.study.length)).then(() => live && setPhase('test'));
    return () => {
      live = false;
    };
  }, [level, ctx]);

  const answer = (seen: boolean) => {
    if (phase !== 'test') return;
    if (w.test[at].seen === seen) ctx.hit(20);
    else ctx.miss({ life: true });
    if (at + 1 < w.test.length) setAt(at + 1);
    else {
      ctx.stat('Rounds', level);
      setLevel(level + 1);
    }
  };

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'ArrowLeft') answer(true);
      if (e.key === 'ArrowRight') answer(false);
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  });

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-6">
      {phase === 'study' ? (
        <>
          <p className="text-sm tracking-widest text-soft">MEMORISE THESE {w.study.length} WORDS</p>
          <div className="glass grid w-full grid-cols-2 gap-2 rounded-3xl p-4 text-center text-2xl">
            {w.study.map((word) => <span key={word} className="outline-text">{word}</span>)}
          </div>
        </>
      ) : (
        <>
          <p className="text-sm tracking-widest text-soft">WAS THIS ON THE LIST? {at + 1}/{w.test.length}</p>
          <m.p key={at} initial={{ scale: 0.8, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="outline-text text-6xl">{w.test[at].word}</m.p>
          <div className="grid w-full grid-cols-2 gap-4">
            <button onClick={() => answer(true)} className="chunky tone-green outline-text h-20 rounded-2xl text-2xl">SEEN ←</button>
            <button onClick={() => answer(false)} className="chunky tone-red outline-text h-20 rounded-2xl text-2xl">NEW →</button>
          </div>
        </>
      )}
    </div>
  );
}
