import { m } from 'framer-motion';
import { useEffect, useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { BLOCKS, STIMULUS_MS, isMatch, makeStream } from './logic';

export default function NBack({ ctx }: GameProps) {
  const [block, setBlock] = useState(0);
  const [i, setI] = useState(-1);
  const [feedback, setFeedback] = useState<'hit' | 'miss' | null>(null);
  const tapped = useRef(false);
  const { n, length } = BLOCKS[block];
  const [stream, setStream] = useState(() => makeStream(BLOCKS[0].n, BLOCKS[0].length, ctx.rng));
  const stats = useRef({ right: 0, total: 0 });

  // one stimulus every STIMULUS_MS; a missed match is judged when it ends
  useEffect(() => {
    let live = true;
    (async () => {
      const s = block === 0 ? stream : makeStream(n, length, ctx.rng);
      if (block > 0) setStream(s);
      setI(-1);
      await ctx.sleep(1500);
      for (let k = 0; k < s.length; k++) {
        if (!live) return;
        tapped.current = false;
        setFeedback(null);
        setI(k);
        await ctx.sleep(STIMULUS_MS);
        if (!live) return;
        if (isMatch(s, k, n) && !tapped.current) ctx.miss();
        if (!tapped.current) {
          stats.current.total++;
          if (!isMatch(s, k, n)) stats.current.right++;
        }
      }
      ctx.stat('Accuracy', `${Math.round((stats.current.right / Math.max(1, stats.current.total)) * 100)}%`);
      if (block + 1 < BLOCKS.length) setBlock(block + 1);
      else ctx.finish();
    })();
    return () => {
      live = false;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [block]);

  const tap = () => {
    if (i < 0 || tapped.current) return;
    tapped.current = true;
    stats.current.total++;
    if (isMatch(stream, i, n)) {
      stats.current.right++;
      ctx.hit(50 * n);
      setFeedback('hit');
    } else {
      ctx.miss();
      setFeedback('miss');
    }
  };

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === ' ' || e.key === 'Enter') {
        e.preventDefault();
        tap();
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  });

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-8">
      <p className="text-center text-sm tracking-widest text-soft">
        {n}-BACK · TAP MATCH WHEN THE LETTER IS THE SAME AS {n === 1 ? 'THE LAST ONE' : `${n} AGO`}
      </p>
      <div className={`tray grid h-44 w-44 place-items-center rounded-3xl ${feedback === 'hit' ? 'ring-4 ring-neon' : feedback === 'miss' ? 'ring-4 ring-danger' : ''}`}>
        {i >= 0 ? (
          <m.span key={`${block}-${i}`} initial={{ scale: 0.6, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="outline-text text-9xl text-volt">{stream[i]}</m.span>
        ) : (
          <span className="outline-text text-4xl">Block {block + 1}/3</span>
        )}
      </div>
      <p className="text-xs text-soft">{i >= 0 ? `${i + 1} / ${length}` : 'Get ready…'}</p>
      <button onClick={tap} className="chunky tone-green outline-text h-20 w-full max-w-xs rounded-2xl text-3xl">MATCH</button>
    </div>
  );
}
