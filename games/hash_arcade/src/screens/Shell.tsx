import { AnimatePresence, animate, m } from 'framer-motion';
import { Component, Suspense, lazy, useEffect, useMemo, useRef, useState, type ReactNode } from 'react';
import { submitScore, shareText } from '../engine/host';
import { useProfile, levelFor, type RunRecord } from '../engine/profile';
import { go } from '../engine/router';
import { mulberry32 } from '../engine/rng';
import { createRun, useSession, type Run } from '../engine/run';
import { sfx } from '../engine/sfx';
import type { GameDef, Mode } from '../engine/types';
import { dailySeed } from '../games/registry';
import { Button, Thumb } from '../ui';

type Phase = 'intro' | 'play' | 'over';

export default function Shell({ def, mode }: { def: GameDef; mode: Mode }) {
  const Game = useMemo(() => lazy(def.load!), [def]);
  const [phase, setPhase] = useState<Phase>('intro');
  const [runNo, setRunNo] = useState(0);
  const [record, setRecord] = useState<RunRecord | null>(null);
  const [run, setRun] = useState<Run | null>(null);
  // where the last tap landed, so hit effects burst from it
  const tapAt = useRef<{ x: number; y: number } | null>(null);

  const start = () => {
    sfx.unlock();
    setRecord(null);
    setRun(null); // never mount the next game with the last run's ctx
    setRunNo((n) => n + 1);
    setPhase('play');
  };

  // one Run per attempt; the game component remounts with it
  useEffect(() => {
    if (phase !== 'play') return;
    const rng = mode === 'daily' ? mulberry32(dailySeed(def.id)) : Math.random;
    const r = createRun(def, mode, rng, () => {
      const score = useSession.getState().score;
      const rec = useProfile.getState().record(def, mode, score);
      // the app's arcade leaderboard ranks the career score; one submission per run
      submitScore(rec.career, `${def.id}-${Date.now()}`);
      setRecord(rec);
      setTimeout(() => setPhase('over'), 500);
    });
    setRun(r);
    return () => r.dispose();
  }, [phase, runNo, def, mode]);

  // leaving the app or the tab pauses the run
  useEffect(() => {
    if (!run) return;
    const onVis = () => document.hidden && run.pause();
    const onKey = (e: KeyboardEvent) => {
      if (e.key !== 'Escape' && e.key !== 'p') return;
      const s = useSession.getState().status;
      if (s === 'playing') run.pause();
      else if (s === 'paused') run.resume();
    };
    document.addEventListener('visibilitychange', onVis);
    window.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('visibilitychange', onVis);
      window.removeEventListener('keydown', onKey);
    };
  }, [run]);

  return (
    <div className="flex h-full flex-col px-4 pb-[calc(env(safe-area-inset-bottom)+12px)] safe-top">
      {phase === 'intro' && <Intro def={def} mode={mode} onStart={start} />}
      {phase === 'play' && run && (
        <>
          <Hud def={def} run={run} />
          <div className="relative min-h-0 flex-1" onPointerDownCapture={(e) => (tapAt.current = { x: e.clientX, y: e.clientY })}>
            <GameBoundary>
              <Suspense fallback={<Loading />}>
                <Game key={runNo} ctx={run.ctx} />
              </Suspense>
            </GameBoundary>
            <MissFlash />
            <HitBurst tapAt={tapAt} />
            {def.combo && <StreakBanner />}
            <Countdown run={run} />
            <PauseOverlay run={run} />
          </div>
        </>
      )}
      {phase === 'over' && record && <Results def={def} mode={mode} record={record} onAgain={start} />}
    </div>
  );
}

function Countdown({ run }: { run: Run }) {
  const counting = useSession((s) => s.status === 'countdown');
  const [n, setN] = useState(3);
  useEffect(() => {
    if (!counting) return;
    sfx.tick();
    const t = setTimeout(() => {
      if (n > 1) setN(n - 1);
      else run.begin();
    }, 600);
    return () => clearTimeout(t);
  }, [n, counting, run]);
  if (!counting) return null;
  // opaque, so nobody gets a free look at the first puzzle
  return (
    <div className="absolute -inset-4 z-30 grid place-items-center bg-ink">
      <m.span
        key={n}
        initial={{ scale: 1.8, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        className="text-8xl font-black text-neon outline-text"
      >
        {n}
      </m.span>
    </div>
  );
}

const reducedMotion = () => window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false;

/** Neon particles from the tapped spot on every hit; drawn with plain DOM nodes, no React renders. */
function HitBurst({ tapAt }: { tapAt: React.MutableRefObject<{ x: number; y: number } | null> }) {
  const gain = useSession((s) => s.lastGain);
  const layer = useRef<HTMLDivElement>(null);
  useEffect(() => {
    const el = layer.current;
    if (!gain || !el || reducedMotion()) return;
    const box = el.getBoundingClientRect();
    const x = (tapAt.current?.x ?? box.left + box.width / 2) - box.left;
    const y = (tapAt.current?.y ?? box.top + box.height / 2) - box.top;
    for (let i = 0; i < 14; i++) {
      const a = (i / 14) * Math.PI * 2 + Math.random() * 0.4;
      const d = 36 + Math.random() * 46;
      const p = document.createElement('div');
      p.className = 'particle';
      p.style.cssText = `left:${x}px;top:${y}px;background:${i % 2 ? '#39ff88' : '#2ec5ff'};--dx:${Math.cos(a) * d}px;--dy:${Math.sin(a) * d}px`;
      el.appendChild(p);
      setTimeout(() => p.remove(), 620);
    }
  }, [gain, tapAt]);
  return <div ref={layer} aria-hidden className="pointer-events-none absolute inset-0 z-10" />;
}

/** Every 5 hits in a row, in games that keep combos. */
function StreakBanner() {
  const combo = useSession((s) => s.combo);
  const show = combo > 0 && combo % 5 === 0;
  useEffect(() => {
    if (show) sfx.streak();
  }, [show, combo]);
  return (
    <AnimatePresence>
      {show && (
        <m.div
          key={combo}
          aria-live="polite"
          initial={{ opacity: 0, scale: 0.5, rotate: -6 }}
          animate={{ opacity: [0, 1, 1, 0], scale: [0.5, 1.1, 1, 1.2], rotate: [-6, 2, 0, 0] }}
          transition={{ duration: 1.1, times: [0, 0.25, 0.8, 1] }}
          className="pointer-events-none absolute inset-0 z-20 grid place-items-center"
        >
          <span className="chunky tone-yellow outline-text rounded-2xl px-6 py-3 text-4xl">
            🔥 {combo} STREAK!
          </span>
        </m.div>
      )}
    </AnimatePresence>
  );
}

function Loading() {
  return <div className="grid h-full place-items-center text-sm text-white/50">Loading…</div>;
}

class GameBoundary extends Component<{ children: ReactNode }, { failed: boolean }> {
  override state = { failed: false };
  static getDerivedStateFromError() {
    return { failed: true };
  }
  override render() {
    if (!this.state.failed) return this.props.children;
    return (
      <div className="grid h-full place-items-center text-center">
        <div>
          <p className="font-bold">This game hit a problem.</p>
          <Button variant="ghost" className="mt-4 px-6" onClick={() => go('')}>Back to arcade</Button>
        </div>
      </div>
    );
  }
}

function Intro({ def, mode, onStart }: { def: GameDef; mode: Mode; onStart: () => void }) {
  const best = useProfile((s) => s.bests[def.id] ?? 0);
  return (
    <m.main initial={{ opacity: 0, y: 12 }} animate={{ opacity: 1, y: 0 }} className="mx-auto flex h-full w-full max-w-sm flex-col">
      <BackButton />
      <div className="flex flex-1 flex-col items-center justify-center text-center">
        <div className="w-32"><Thumb def={def} size="lg" /></div>
        {mode === 'daily' && <p className="mt-5 text-xs font-black tracking-[0.3em] text-volt">DAILY CHALLENGE</p>}
        <h1 className="mt-2 text-4xl font-black tracking-tight">{def.name}</h1>
        <p className="mt-1 text-white/60">{def.blurb}</p>
        <ul className="glass mt-6 w-full space-y-2 rounded-2xl p-4 text-left text-sm text-white/75">
          {def.howTo.map((h) => (
            <li key={h} className="flex gap-2"><span className="text-neon">›</span>{h}</li>
          ))}
        </ul>
        <p className="mt-4 text-sm text-white/55">Best <span className="font-black text-neon">{best.toLocaleString()}</span></p>
      </div>
      <Button onClick={onStart} autoFocus className="w-full text-xl">PLAY</Button>
    </m.main>
  );
}

function BackButton() {
  return (
    <button onClick={() => go('')} aria-label="Back to arcade" className="web-back clear-back glass grid h-11 w-11 place-items-center rounded-full text-xl">
      ‹
    </button>
  );
}

function Hud({ def, run }: { def: GameDef; run: Run }) {
  const { score, combo, lives, lastGain } = useSession();
  const rootRef = useRef<HTMLDivElement>(null);
  const barRef = useRef<HTMLDivElement>(null);
  const textRef = useRef<HTMLSpanElement>(null);
  const scoreRef = useRef<HTMLSpanElement>(null);
  const shown = useRef(0);

  // the clock is drawn straight to the DOM each frame, never through React
  useEffect(() => {
    if (def.duration == null) return;
    let peak = def.duration;
    const draw = () => {
      const t = Math.max(0, run.timeLeft());
      peak = Math.max(peak, t); // bar is relative to the most time banked, so it always drains
      if (textRef.current) textRef.current.textContent = t.toFixed(1);
      if (barRef.current) barRef.current.style.transform = `scaleX(${t / peak})`;
      rootRef.current?.classList.toggle('warn', t <= 5);
    };
    draw();
    return run.ctx.onFrame(draw);
  }, [def, run]);

  // count the score up rather than jumping
  useEffect(() => {
    const from = shown.current;
    shown.current = score;
    const c = animate(from, score, {
      duration: 0.35,
      onUpdate: (v) => {
        if (scoreRef.current) scoreRef.current.textContent = Math.round(v).toLocaleString();
      },
    });
    return () => c.stop();
  }, [score]);

  return (
    <header ref={rootRef} className="mx-auto mb-3 flex w-full max-w-2xl flex-col gap-2">
      <div className="clear-back flex items-center gap-3">
        <button onClick={run.pause} aria-label="Pause" className="glass grid h-11 w-11 shrink-0 place-items-center rounded-full font-black">
          ❚❚
        </button>
        <div className="relative">
          <div className="text-[10px] font-bold tracking-[0.2em] text-white/50">SCORE</div>
          <span ref={scoreRef} className="text-2xl font-black tabular-nums text-neon outline-text">0</span>
          <AnimatePresence>
            {lastGain && (
              <m.span
                key={lastGain.id}
                initial={{ opacity: 1, y: 0 }}
                animate={{ opacity: 0, y: -18 }}
                transition={{ duration: 0.7 }}
                className="pointer-events-none absolute left-full top-3 ml-2 text-sm font-black text-neon"
              >
                +{lastGain.points}
              </m.span>
            )}
          </AnimatePresence>
        </div>
        <div className="ml-auto flex items-center gap-3 text-right">
          {def.combo && combo >= 3 && (
            <span className="text-lg font-black text-volt outline-text">{Math.min(5, 1 + Math.floor(combo / 3))}×</span>
          )}
          {lives != null && (
            <span aria-label={`${lives} lives`} className="text-lg tracking-wider">
              {Array.from({ length: def.lives! }, (_, i) => (i < lives ? '♥' : '♡')).join('')}
            </span>
          )}
          {def.duration != null && (
            <span ref={textRef} role="timer" className="timer-text text-3xl font-black tabular-nums outline-text">
              {def.duration.toFixed(1)}
            </span>
          )}
        </div>
      </div>
      {def.duration != null && (
        <div className="tray h-4 overflow-hidden rounded-full">
          <div ref={barRef} className="timer-bar h-full rounded-full" />
        </div>
      )}
    </header>
  );
}

function MissFlash() {
  const miss = useSession((s) => s.lastMiss);
  if (!miss) return null;
  return (
    <m.div
      key={miss}
      aria-hidden
      initial={{ opacity: 0.45 }}
      animate={{ opacity: 0 }}
      transition={{ duration: 0.4 }}
      className="pointer-events-none absolute -inset-4 z-20 bg-danger/40"
    />
  );
}

function PauseOverlay({ run }: { run: Run }) {
  const paused = useSession((s) => s.status === 'paused');
  if (!paused) return null;
  // covers the board so a pause can't be used to study the puzzle
  return (
    <div className="absolute -inset-4 z-30 grid place-items-center bg-ink/90 backdrop-blur-md">
      <div className="flex w-56 flex-col gap-3 text-center">
        <p className="text-3xl font-black">PAUSED</p>
        <Button onClick={run.resume} autoFocus>RESUME</Button>
        <Button variant="ghost" onClick={run.ctx.finish}>END RUN</Button>
        <Button variant="ghost" onClick={() => go('')}>QUIT</Button>
      </div>
    </div>
  );
}

function Results({ def, mode, record, onAgain }: { def: GameDef; mode: Mode; record: RunRecord; onAgain: () => void }) {
  const { score, hits, misses, maxCombo, stats } = useSession();
  const xp = useProfile((s) => s.xp);
  const [msg, setMsg] = useState('');
  const newBest = score > record.prevBest;
  const accuracy = hits + misses ? Math.round((hits / (hits + misses)) * 100) : null;

  const rows: [string, string | number][] = [
    ['Best', Math.max(score, record.prevBest).toLocaleString()],
    ...(accuracy != null ? [['Accuracy', `${accuracy}%`] as [string, string]] : []),
    ...(def.combo ? [['Max combo', maxCombo] as [string, number]] : []),
    ...Object.entries(stats),
  ];

  const share = async () => {
    const label = mode === 'daily' ? `${def.name} · Daily` : def.name;
    const res = await shareText(`🎮 Hash Arcade · ${label}: ${score.toLocaleString()} pts. Can you beat it? Play on Hash For Gamers.`);
    setMsg(res === 'copied' ? 'Copied to clipboard!' : res === 'failed' ? 'Could not share' : '');
  };

  return (
    <m.main initial={{ opacity: 0, scale: 0.96 }} animate={{ opacity: 1, scale: 1 }} className="flex h-full items-center justify-center">
      <div className="glass w-full max-w-sm rounded-3xl p-6 text-center">
        <p className="text-xs font-bold tracking-[0.3em] text-white/50">{mode === 'daily' ? 'DAILY CHALLENGE' : def.name.toUpperCase()}</p>
        <div className="mt-2 text-6xl font-black tabular-nums text-neon outline-text">{score.toLocaleString()}</div>
        {newBest && <div className="chunky tone-yellow outline-text mt-2 inline-block rounded-full px-4 py-1 text-sm tracking-widest">★ NEW BEST</div>}
        <dl className="mt-5 grid grid-cols-2 gap-2.5">
          {rows.map(([k, v]) => (
            <div key={k} className="tray rounded-2xl px-3 py-2.5">
              <dt className="text-[10px] font-bold uppercase tracking-[0.2em] text-white/50">{k}</dt>
              <dd className="text-xl font-black tabular-nums">{v}</dd>
            </div>
          ))}
        </dl>
        <p className="mt-4 text-sm text-volt">
          +{record.xpGained} XP{record.levelUp && <span className="font-black text-neon"> · LEVEL {levelFor(xp)}!</span>}
        </p>
        <Button onClick={onAgain} autoFocus className="mt-5 w-full text-lg">PLAY AGAIN</Button>
        <div className="mt-3 grid grid-cols-2 gap-3">
          <Button variant="outline" onClick={share}>SHARE</Button>
          <Button variant="ghost" onClick={() => go('')}>ARCADE</Button>
        </div>
        <p aria-live="polite" className="mt-2 h-4 text-xs text-white/60">{msg}</p>
      </div>
    </m.main>
  );
}
