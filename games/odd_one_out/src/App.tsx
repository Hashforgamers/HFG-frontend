import { memo, useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState } from 'react';
import {
  BASE_POINTS, CORRECT_BONUS, START_TIME, WRONG_PENALTY,
  hashString, makePuzzle, mulberry32, multiplier, rankFor, todayKey,
  type Puzzle, type Rng,
} from './game';
import { haptic, shareText, store, submitScore } from './host';
import { sfx } from './sfx';

type Mode = 'classic' | 'daily';

interface Result {
  mode: Mode;
  score: number;
  hits: number;
  misses: number;
  maxCombo: number;
  level: number;
  prevBest?: number;
}

const MIN_CELL = 26; // px — smallest cell a grid may shrink to and still be tappable
const BEST_KEY = 'ooo_best';
const dailyKey = () => `ooo_daily_${todayKey()}`;
const readNum = (k: string) => Number(store.get(k)) || 0;
const reducedMotion = () => window.matchMedia?.('(prefers-reduced-motion: reduce)').matches ?? false;

export default function App() {
  const [screen, setScreen] = useState<'start' | 'play' | 'over'>('start');
  const [mode, setMode] = useState<Mode>('classic');
  const [result, setResult] = useState<Result | null>(null);
  const [runKey, setRunKey] = useState(0);
  const [soundOn, setSoundOn] = useState(() => store.get('ooo_sound') !== 'off');

  useEffect(() => {
    sfx.enabled = soundOn;
    store.set('ooo_sound', soundOn ? 'on' : 'off');
  }, [soundOn]);

  const start = (m: Mode) => {
    sfx.unlock();
    setMode(m);
    setRunKey((k) => k + 1);
    setScreen('play');
  };

  const finish = useCallback((r: Result) => {
    const key = r.mode === 'daily' ? dailyKey() : BEST_KEY;
    const prevBest = readNum(key);
    if (r.score > prevBest) store.set(key, String(r.score));
    submitScore(r.score, `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`);
    setResult({ ...r, prevBest });
    setScreen('over');
  }, []);

  const sound = <SoundToggle on={soundOn} toggle={() => setSoundOn((s) => !s)} />;

  return (
    <div className="bg-grid relative h-full overflow-hidden">
      {screen === 'start' && <StartScreen onPlay={start} sound={sound} />}
      {screen === 'play' && <Play key={runKey} mode={mode} onOver={finish} sound={sound} />}
      {screen === 'over' && result && (
        <GameOver result={result} onAgain={() => start(result.mode)} onHome={() => setScreen('start')} />
      )}
    </div>
  );
}

function SoundToggle({ on, toggle }: { on: boolean; toggle: () => void }) {
  return (
    <button
      onClick={toggle}
      aria-label={on ? 'Mute sound' : 'Unmute sound'}
      aria-pressed={!on}
      className="glass grid h-11 w-11 place-items-center rounded-full text-lg"
    >
      {on ? '🔊' : '🔇'}
    </button>
  );
}

/* ───────────────────────── Start ───────────────────────── */

const FLOAT_CHARS = '?2O0B8S5Q#@XK69MN';

function StartScreen({ onPlay, sound }: { onPlay: (m: Mode) => void; sound: React.ReactNode }) {
  const best = readNum(BEST_KEY);
  const dailyBest = readNum(dailyKey());
  const floaters = useMemo(
    () =>
      Array.from({ length: 26 }, (_, i) => ({
        ch: FLOAT_CHARS[i % FLOAT_CHARS.length],
        left: Math.random() * 100,
        size: 16 + Math.random() * 40,
        dur: 9 + Math.random() * 12,
        delay: -Math.random() * 20,
        o: 0.08 + Math.random() * 0.22,
        rot: `${Math.round(Math.random() * 360 - 180)}deg`,
        neon: i % 3 === 0,
      })),
    [],
  );
  const date = new Date().toLocaleDateString(undefined, { day: 'numeric', month: 'short' });

  return (
    <main className="relative flex h-full flex-col items-center justify-center px-5 pb-[env(safe-area-inset-bottom)] pt-[env(safe-area-inset-top)]">
      <div aria-hidden className="pointer-events-none absolute inset-0 overflow-hidden">
        {floaters.map((f, i) => (
          <span
            key={i}
            className={`floaty ${f.neon ? 'text-neon' : 'text-volt'}`}
            style={{
              left: `${f.left}%`,
              fontSize: f.size,
              animationDuration: `${f.dur}s`,
              animationDelay: `${f.delay}s`,
              ['--o' as string]: f.o,
              ['--rot' as string]: f.rot,
            }}
          >
            {f.ch}
          </span>
        ))}
      </div>

      <div className="absolute right-4 top-[calc(env(safe-area-inset-top)+16px)]">{sound}</div>

      <div className="pop-in relative flex w-full max-w-sm flex-col items-center text-center">
        <p className="text-xs font-bold tracking-[0.35em] text-volt">HASH FOR GAMERS</p>
        <h1 className="mt-3 text-6xl font-black leading-[0.9] tracking-tight">
          <span className="block">ODD</span>
          <span className="block text-neon glow-neon">ONE OUT</span>
        </h1>
        <p className="mt-3 text-sm text-white/60">One different. Find it fast.</p>

        <button
          onClick={() => onPlay('classic')}
          className="mt-9 w-full rounded-2xl bg-neon py-4 text-xl font-black tracking-wider text-ink shadow-[0_0_32px_rgb(57_255_136/0.45)] transition active:scale-95"
          autoFocus
        >
          PLAY NOW
        </button>
        <button
          onClick={() => onPlay('daily')}
          className="glass mt-3 flex w-full items-center justify-between rounded-2xl px-5 py-3.5 text-left transition active:scale-95"
        >
          <span>
            <span className="block text-sm font-black tracking-wider text-volt">DAILY CHALLENGE</span>
            <span className="block text-xs text-white/55">Same puzzles for everyone · {date}</span>
          </span>
          <span className="text-right text-xs text-white/55">
            Today
            <span className="block text-base font-bold text-white">{dailyBest || '—'}</span>
          </span>
        </button>

        <div className="mt-5 text-sm text-white/60">
          Personal best <span className="font-black text-neon glow-neon">{best.toLocaleString()}</span>
        </div>

        <details className="glass mt-6 w-full rounded-2xl px-5 py-3 text-left text-sm text-white/75">
          <summary className="cursor-pointer font-bold text-white">How to play</summary>
          <ul className="mt-2 list-disc space-y-1 pl-5">
            <li>Every grid hides exactly one different character. Tap it.</li>
            <li>Right: +{BASE_POINTS} × combo and +{CORRECT_BONUS}s. Wrong: −{WRONG_PENALTY}s and combo resets.</li>
            <li>Hit streaks raise your multiplier up to 5×.</li>
            <li>Grids grow and get sneakier every round. Keyboard: arrows + Enter.</li>
          </ul>
        </details>
      </div>
    </main>
  );
}

/* ───────────────────────── Play ───────────────────────── */

interface Hud {
  score: number;
  level: number;
  mult: number;
  hits: number;
  misses: number;
}

function Play({ mode, onOver, sound }: { mode: Mode; onOver: (r: Result) => void; sound: React.ReactNode }) {
  const [puzzle, setPuzzle] = useState<(Puzzle & { id: number }) | null>(null);
  const [hud, setHud] = useState<Hud>({ score: 0, level: 1, mult: 1, hits: 0, misses: 0 });
  const [banner, setBanner] = useState<{ id: number; text: string } | null>(null);

  const rootRef = useRef<HTMLDivElement>(null);
  const areaRef = useRef<HTMLDivElement>(null);
  const fxRef = useRef<HTMLDivElement>(null);
  const timerTextRef = useRef<HTMLSpanElement>(null);
  const barRef = useRef<HTMLDivElement>(null);
  const time = useRef(START_TIME);
  const ended = useRef(false);
  const run = useRef({ score: 0, level: 1, streak: 0, maxCombo: 0, hits: 0, misses: 0 });
  const rng = useRef<Rng>(mode === 'daily' ? mulberry32(hashString(todayKey())) : Math.random);
  const fit = useRef({ cols: 15, rows: 15 });
  const puzzleRef = useRef(puzzle);
  puzzleRef.current = puzzle;

  const next = useCallback((level: number) => {
    const p = makePuzzle(level, rng.current, fit.current.cols, fit.current.rows);
    setPuzzle({ ...p, id: level });
  }, []);

  // Size the next grids to what fits at a tappable cell size.
  useLayoutEffect(() => {
    const el = areaRef.current!;
    const measure = () => {
      fit.current = {
        cols: Math.floor(el.clientWidth / MIN_CELL),
        rows: Math.floor(el.clientHeight / MIN_CELL),
      };
    };
    measure();
    next(1);
    const ro = new ResizeObserver(measure);
    ro.observe(el);
    return () => ro.disconnect();
  }, [next]);

  const end = useCallback(() => {
    if (ended.current) return;
    ended.current = true;
    sfx.over();
    haptic('heavy');
    const r = run.current;
    // brief beat so the last frame reads as "time up" before the screen swaps
    setTimeout(
      () => onOver({ mode, score: r.score, hits: r.hits, misses: r.misses, maxCombo: r.maxCombo, level: r.level }),
      450,
    );
  }, [mode, onOver]);

  // Timer: one rAF loop writing straight to the DOM, so ticking never re-renders React.
  useEffect(() => {
    let raf = 0;
    let last = performance.now();
    let lastSec = Math.ceil(time.current);
    // bar is relative to the most time banked, so it keeps draining once hits push past 30s
    let peak = START_TIME;
    const frame = (now: number) => {
      // clamp: a backgrounded tab pauses rAF, and the clock should pause with it
      time.current -= Math.min(now - last, 100) / 1000;
      last = now;
      const t = Math.max(0, time.current);
      timerTextRef.current!.textContent = t.toFixed(1);
      peak = Math.max(peak, t);
      barRef.current!.style.transform = `scaleX(${t / peak})`;
      rootRef.current!.classList.toggle('warn', t <= 5);
      const sec = Math.ceil(t);
      if (sec !== lastSec) {
        lastSec = sec;
        if (sec <= 5 && sec > 0) {
          sfx.tick();
          haptic('light');
        }
      }
      if (t <= 0) return end();
      raf = requestAnimationFrame(frame);
    };
    raf = requestAnimationFrame(frame);
    return () => cancelAnimationFrame(raf);
  }, [end]);

  const burst = (el: HTMLElement, text: string, color: string, particles: boolean) => {
    const fx = fxRef.current!;
    const box = fx.getBoundingClientRect();
    const r = el.getBoundingClientRect();
    const x = r.left - box.left + r.width / 2;
    const y = r.top - box.top + r.height / 2;
    const add = (node: HTMLElement, ms: number) => {
      fx.appendChild(node);
      setTimeout(() => node.remove(), ms);
    };
    const label = document.createElement('div');
    label.className = 'float-text text-lg';
    label.style.cssText = `left:${x}px;top:${y}px;color:${color}`;
    label.textContent = text;
    add(label, 800);
    if (!particles || reducedMotion()) return;
    for (let i = 0; i < 16; i++) {
      const a = (i / 16) * Math.PI * 2 + Math.random() * 0.4;
      const d = 40 + Math.random() * 50;
      const p = document.createElement('div');
      p.className = 'particle';
      p.style.cssText = `left:${x}px;top:${y}px;background:${i % 2 ? '#39ff88' : '#2ec5ff'};--dx:${Math.cos(a) * d}px;--dy:${Math.sin(a) * d}px`;
      add(p, 620);
    }
  };

  const pick = useCallback((i: number, el: HTMLElement) => {
    const p = puzzleRef.current;
    if (!p || ended.current) return;
    const r = run.current;
    if (i === p.oddIndex) {
      r.hits++;
      r.streak++;
      r.maxCombo = Math.max(r.maxCombo, r.streak);
      const mult = multiplier(r.streak);
      const pts = BASE_POINTS * mult;
      r.score += pts;
      r.level++;
      time.current += CORRECT_BONUS;
      sfx.correct(mult);
      haptic('light');
      burst(el, `+${pts}`, '#39ff88', true);
      if (r.streak % 5 === 0) {
        setBanner({ id: r.hits, text: `${r.streak} STREAK!` });
        sfx.streak();
        haptic('medium');
      }
      next(r.level);
    } else {
      r.misses++;
      r.streak = 0;
      time.current -= WRONG_PENALTY;
      sfx.wrong();
      haptic('heavy');
      burst(el, `−${WRONG_PENALTY}s`, '#ff3b5c', false);
      el.classList.remove('bad');
      void el.offsetWidth; // restart the shake animation
      el.classList.add('bad');
      const root = rootRef.current!;
      root.classList.remove('miss-flash');
      void root.offsetWidth;
      root.classList.add('miss-flash');
    }
    setHud({ score: r.score, level: r.level, mult: multiplier(r.streak), hits: r.hits, misses: r.misses });
  }, [next]);

  const total = hud.hits + hud.misses;
  const accuracy = total ? Math.round((hud.hits / total) * 100) : 100;
  const tier = puzzle?.tier ?? 'EASY';

  return (
    <div
      ref={rootRef}
      className="relative flex h-full flex-col gap-3 px-4 pb-[calc(env(safe-area-inset-bottom)+12px)] pt-[calc(env(safe-area-inset-top)+12px)]"
    >
      <div aria-hidden className="vignette pointer-events-none absolute inset-0 z-20" />

      {/* top: timer, score, level */}
      <header className="mx-auto flex w-full max-w-2xl flex-col gap-2.5">
        <div className="flex items-center justify-between gap-3">
          <div className="glass rounded-2xl px-4 py-1.5">
            <div className="text-[10px] font-bold tracking-[0.2em] text-white/50">SCORE</div>
            <div className="text-2xl font-black tabular-nums text-neon glow-neon">{hud.score.toLocaleString()}</div>
          </div>
          <div className="text-center" role="timer" aria-label="Time left">
            <span ref={timerTextRef} className="timer-text inline-block text-4xl font-black tabular-nums glow-volt">
              {START_TIME.toFixed(1)}
            </span>
          </div>
          <div className="flex items-center gap-2">
            <div className="glass rounded-2xl px-4 py-1.5 text-right">
              <div className="text-[10px] font-bold tracking-[0.2em] whitespace-nowrap text-white/50">LV · {tier}</div>
              <div className="text-2xl font-black tabular-nums">{hud.level}</div>
            </div>
          </div>
        </div>
        <div className="h-2 overflow-hidden rounded-full bg-white/10">
          <div ref={barRef} className="timer-bar h-full rounded-full" />
        </div>
      </header>

      {/* center: grid */}
      <div ref={areaRef} className="board-area relative mx-auto grid min-h-0 w-full max-w-2xl flex-1 place-items-center">
        {puzzle && <Board key={puzzle.id} puzzle={puzzle} onPick={pick} />}
        <div ref={fxRef} aria-hidden className="pointer-events-none absolute inset-0 z-10" />
        {banner && (
          <div key={banner.id} aria-live="polite" className="pointer-events-none absolute inset-0 z-10 grid place-items-center">
            <div className="banner rounded-2xl bg-neon/15 px-6 py-3 text-4xl font-black italic text-neon glow-neon backdrop-blur-sm">
              🔥 {banner.text}
            </div>
          </div>
        )}
      </div>

      {/* bottom: combo + accuracy */}
      <footer className="mx-auto flex w-full max-w-2xl items-center justify-between gap-2">
        <div className="glass flex items-center gap-2 rounded-2xl px-3 py-2">
          <span className="text-[10px] font-bold tracking-[0.2em] text-white/50">COMBO</span>
          <span
            key={hud.mult}
            className={`pop-in text-2xl font-black ${hud.mult > 1 ? 'text-volt glow-volt' : 'text-white/70'}`}
          >
            {hud.mult}×
          </span>
          <span className="flex gap-1" aria-hidden>
            {[1, 2, 3, 4, 5].map((m) => (
              <span key={m} className={`h-2 w-2 rounded-full ${m <= hud.mult ? 'bg-volt' : 'bg-white/15'}`} />
            ))}
          </span>
        </div>
        <div className="flex items-center gap-2">
          <div className="glass rounded-2xl px-3 py-2 text-right">
            <span className="text-[10px] font-bold tracking-[0.2em] text-white/50">ACC </span>
            <span className="text-lg font-black tabular-nums">{accuracy}%</span>
          </div>
          {sound}
        </div>
      </footer>
    </div>
  );
}

const Board = memo(function Board({
  puzzle,
  onPick,
}: {
  puzzle: Puzzle;
  onPick: (i: number, el: HTMLElement) => void;
}) {
  const { rows, cols, base, odd, oddIndex } = puzzle;
  const count = rows * cols;
  const gridRef = useRef<HTMLDivElement>(null);
  // roving tabindex: one tab stop for the whole grid, arrows move inside it
  const [focus, setFocus] = useState(() => Math.floor(count / 2));

  useEffect(() => {
    // keyboard players keep focus in the grid across rounds
    if (document.activeElement?.closest('.board')) {
      (gridRef.current?.children[focus] as HTMLElement | undefined)?.focus({ preventScroll: true });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const onKeyDown = (e: React.KeyboardEvent) => {
    const step = { ArrowLeft: -1, ArrowRight: 1, ArrowUp: -cols, ArrowDown: cols }[e.key];
    if (step === undefined) return;
    e.preventDefault();
    const n = Math.min(count - 1, Math.max(0, focus + step));
    setFocus(n);
    (gridRef.current?.children[n] as HTMLElement | undefined)?.focus();
  };

  return (
    <div
      ref={gridRef}
      role="grid"
      aria-label={`Find the odd character in a ${cols} by ${rows} grid`}
      className="board pop-in"
      style={{ ['--c' as string]: cols, ['--r' as string]: rows }}
      onKeyDown={onKeyDown}
    >
      {Array.from({ length: count }, (_, i) => (
        <button
          key={i}
          tabIndex={i === focus ? 0 : -1}
          className="cell"
          onPointerDown={(e) => {
            // pointerdown, not click: saves ~100ms per tap, which matters at speed
            if (e.button !== 0) return;
            e.preventDefault();
            onPick(i, e.currentTarget);
          }}
          onKeyDown={(e) => {
            if (e.key === 'Enter' || e.key === ' ') {
              e.preventDefault();
              onPick(i, e.currentTarget);
            }
          }}
          onFocus={() => setFocus(i)}
        >
          {i === oddIndex ? odd : base}
        </button>
      ))}
    </div>
  );
});

/* ───────────────────────── Game over ───────────────────────── */

function GameOver({ result, onAgain, onHome }: { result: Result; onAgain: () => void; onHome: () => void }) {
  const { score, hits, misses, maxCombo, mode } = result;
  const prevBest = result.prevBest ?? 0;
  const best = Math.max(prevBest, score);
  const isNewBest = score > prevBest;
  const accuracy = hits + misses ? Math.round((hits / (hits + misses)) * 100) : 0;
  const rank = rankFor(score);
  const [shareMsg, setShareMsg] = useState('');

  const share = async () => {
    const label = mode === 'daily' ? `Daily ${todayKey()}` : 'Hash: Odd One Out';
    const res = await shareText(
      `🎯 ${label}: ${score.toLocaleString()} pts · ${hits} found · ${accuracy}% accuracy · ${rank.title}\nCan you beat me? Play on Hash For Gamers.`,
    );
    setShareMsg(res === 'copied' ? 'Copied to clipboard!' : res === 'failed' ? 'Could not share' : '');
  };

  const stats: [string, string][] = [
    ['BEST', best.toLocaleString()],
    ['FOUND', String(hits)],
    ['ACCURACY', `${accuracy}%`],
    ['MAX COMBO', String(maxCombo)],
  ];

  return (
    <main className="flex h-full items-center justify-center px-5 pb-[env(safe-area-inset-bottom)] pt-[env(safe-area-inset-top)]">
      <div className="pop-in glass w-full max-w-sm rounded-3xl p-6 text-center">
        <p className="text-xs font-bold tracking-[0.35em] text-white/50">
          {mode === 'daily' ? 'DAILY CHALLENGE' : 'TIME UP'}
        </p>
        <div className="mt-2 text-sm font-black tracking-[0.25em] text-volt glow-volt">{rank.title}</div>
        <div className="mt-1 text-6xl font-black tabular-nums text-neon glow-neon">{score.toLocaleString()}</div>
        {isNewBest && (
          <div className="mt-2 inline-block rounded-full bg-neon/15 px-3 py-1 text-xs font-black tracking-widest text-neon">
            ★ NEW BEST
          </div>
        )}
        <dl className="mt-5 grid grid-cols-2 gap-2.5">
          {stats.map(([k, v]) => (
            <div key={k} className="rounded-2xl bg-white/5 px-3 py-2.5">
              <dt className="text-[10px] font-bold tracking-[0.2em] text-white/50">{k}</dt>
              <dd className="text-xl font-black tabular-nums">{v}</dd>
            </div>
          ))}
        </dl>
        <button
          onClick={onAgain}
          autoFocus
          className="mt-6 w-full rounded-2xl bg-neon py-4 text-lg font-black tracking-wider text-ink shadow-[0_0_28px_rgb(57_255_136/0.4)] transition active:scale-95"
        >
          PLAY AGAIN
        </button>
        <div className="mt-3 grid grid-cols-2 gap-3">
          <button onClick={share} className="rounded-2xl border border-volt/50 py-3 font-black tracking-wider text-volt transition active:scale-95">
            SHARE SCORE
          </button>
          <button onClick={onHome} className="rounded-2xl border border-white/15 py-3 font-bold tracking-wider text-white/70 transition active:scale-95">
            HOME
          </button>
        </div>
        <p aria-live="polite" className="mt-2 h-4 text-xs text-white/60">{shareMsg}</p>
      </div>
    </main>
  );
}
