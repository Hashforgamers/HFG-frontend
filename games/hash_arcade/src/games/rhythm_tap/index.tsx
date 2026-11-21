import { useEffect, useRef, useState } from 'react';
import { sfx } from '../../engine/sfx';
import type { GameProps } from '../../engine/types';
import { GOOD_MS, LEAD_MS, judge, makeChart, type Judgement } from './logic';

export default function RhythmTap({ ctx }: GameProps) {
  const [chart] = useState(() => makeChart(ctx.rng));
  const done = useRef<Set<number>>(new Set());
  const start = useRef(ctx.now());
  const [now, setNow] = useState(0);
  const [last, setLast] = useState<{ j: Judgement; id: number } | null>(null);
  const counts = useRef({ perfect: 0, good: 0, miss: 0 });
  const beat = 60000 / chart.bpm;

  useEffect(() => {
    start.current = ctx.now();
    let lastBeat = -1;
    return ctx.onFrame((t) => {
      const songT = t - start.current;
      setNow(songT);
      const b = Math.floor((songT - LEAD_MS - 800) / beat);
      if (b !== lastBeat && b >= 0 && b < 32) {
        lastBeat = b;
        sfx.tick(); // the metronome
      }
      chart.notes.forEach((at, i) => {
        if (!done.current.has(i) && songT - at > GOOD_MS) {
          done.current.add(i);
          counts.current.miss++;
          ctx.miss();
          setLast({ j: 'miss', id: i });
        }
      });
      if (songT > chart.lengthMs) {
        const { perfect, good } = counts.current;
        ctx.stat('Perfect', perfect);
        ctx.stat('Good', good);
        ctx.finish();
      }
    });
  }, [chart, beat, ctx]);

  const tap = () => {
    const songT = ctx.now() - start.current;
    let best = -1;
    chart.notes.forEach((at, i) => {
      if (!done.current.has(i) && (best < 0 || Math.abs(at - songT) < Math.abs(chart.notes[best] - songT))) best = i;
    });
    if (best < 0) return;
    const j = judge(songT - chart.notes[best]);
    if (j === 'miss') return; // a stray tap far from any note is ignored
    done.current.add(best);
    counts.current[j]++;
    ctx.hit(j === 'perfect' ? 100 : 50);
    setLast({ j, id: best });
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
    <div className="mx-auto flex h-full max-w-md flex-col items-center gap-3">
      <p className="text-sm tracking-widest text-soft">TAP AS EACH NOTE HITS THE LINE</p>
      <button
        onPointerDown={(e) => { e.preventDefault(); tap(); }}
        aria-label="Tap on the beat"
        className="tray relative w-full flex-1 overflow-hidden rounded-3xl"
      >
        <span className="absolute inset-x-0 bottom-[18%] h-1.5 bg-volt shadow-[0_0_12px_#ffe45c]" />
        {chart.notes.map((at, i) => {
          const until = at - now;
          if (done.current.has(i) || until > LEAD_MS || until < -GOOD_MS) return null;
          const y = 82 - (until / LEAD_MS) * 82; // top → hit line at 82%
          return <span key={i} className="chunky tone-purple absolute left-1/2 h-[7%] w-[38%] -translate-x-1/2 -translate-y-1/2 rounded-2xl" style={{ top: `${y}%` }} />;
        })}
        {last && (
          <span key={last.id} className={`outline-text absolute inset-x-0 top-[40%] text-center text-4xl ${last.j === 'miss' ? 'text-danger' : last.j === 'perfect' ? 'text-neon' : 'text-volt'}`}>
            {last.j.toUpperCase()}
          </span>
        )}
      </button>
    </div>
  );
}
