import { m } from 'framer-motion';
import { levelFor, useProfile, xpForLevel } from '../engine/profile';
import { go } from '../engine/router';
import { todayKey } from '../engine/rng';
import type { GameDef } from '../engine/types';
import { CATEGORIES, GAMES, PLAYABLE, dailyGames } from '../games/registry';
import { Thumb } from '../ui';

export default function Home() {
  const daily = dailyGames();
  const today = useProfile((s) => s.daily[todayKey()]) ?? {};
  const streak = useProfile((s) => s.streak.count);
  return (
    <main className="no-scrollbar h-full overflow-y-auto px-4 pb-[calc(env(safe-area-inset-bottom)+24px)] safe-top">
      <div className="mx-auto max-w-2xl">
        <header className="clear-back flex items-center justify-between">
          <div>
            <p className="text-[10px] font-bold tracking-[0.35em] text-volt">HASH FOR GAMERS</p>
            <h1 className="whitespace-nowrap text-[clamp(1.35rem,6vw,1.75rem)] font-black leading-tight tracking-tight">
              HASH <span className="text-neon outline-text">ARCADE</span>
            </h1>
          </div>
          <ProfileChip />
        </header>

        <section className="mt-6">
          <SectionTitle title="Daily Challenge" note={streak > 0 ? `🔥 ${streak}-day streak` : 'Same puzzles for everyone'} />
          <div className="grid grid-cols-3 gap-3">
            {daily.map((g) => (
              <m.button
                key={g.id}
                whileTap={{ scale: 0.95 }}
                onClick={() => go(`daily/${g.id}`)}
                className="glass rounded-2xl p-2.5 text-left"
              >
                <Thumb def={g} />
                <p className="mt-2 line-clamp-2 min-h-[2.5em] text-sm font-bold leading-tight">{g.name}</p>
                <p className="text-xs text-white/55">{today[g.id] != null ? `Best ${today[g.id].toLocaleString()}` : 'Not played'}</p>
              </m.button>
            ))}
          </div>
        </section>

        {CATEGORIES.map((cat) => {
          const games = GAMES.filter((g) => g.category === cat.id);
          const live = games.filter((g) => g.load).length;
          return (
            <section key={cat.id} className="mt-7">
              <SectionTitle title={cat.name} note={`${live} of ${games.length} live`} />
              <div className="no-scrollbar -mx-4 flex gap-3 overflow-x-auto px-4 pb-1">
                {[...games].sort((a, b) => Number(!!b.load) - Number(!!a.load)).map((g) => (
                  <GameCard key={g.id} def={g} />
                ))}
              </div>
            </section>
          );
        })}

        <p className="mt-8 text-center text-xs text-white/35">
          {PLAYABLE.length === GAMES.length ? `All ${GAMES.length} games live` : `${PLAYABLE.length} of ${GAMES.length} games live · more every update`}
        </p>
      </div>
    </main>
  );
}

function SectionTitle({ title, note }: { title: string; note: string }) {
  return (
    <div className="mb-3 flex items-baseline justify-between">
      <h2 className="text-lg font-black tracking-tight">{title}</h2>
      <span className="text-xs text-white/45">{note}</span>
    </div>
  );
}

function GameCard({ def }: { def: GameDef }) {
  const best = useProfile((s) => s.bests[def.id]);
  const live = !!def.load;
  return (
    <m.button
      whileTap={live ? { scale: 0.95 } : undefined}
      onClick={() => live && go(`play/${def.id}`)}
      aria-disabled={!live}
      className={`w-28 shrink-0 text-left ${live ? '' : 'opacity-40'}`}
    >
      <div className="relative">
        <Thumb def={def} />
        {!live && (
          <span className="absolute right-1.5 top-1.5 rounded-full bg-black/70 px-2 py-0.5 text-[9px] font-black tracking-widest text-white/80">
            SOON
          </span>
        )}
      </div>
      <p className="mt-1.5 truncate text-sm font-bold">{def.name}</p>
      <p className="truncate text-xs text-white/50">{live ? (best ? `Best ${best.toLocaleString()}` : def.blurb) : def.blurb}</p>
    </m.button>
  );
}

function ProfileChip() {
  const xp = useProfile((s) => s.xp);
  const streak = useProfile((s) => s.streak.count);
  const level = levelFor(xp);
  const into = xp - xpForLevel(level);
  const span = xpForLevel(level + 1) - xpForLevel(level);
  return (
    <button onClick={() => go('profile')} aria-label="Your profile" className="glass flex shrink-0 items-center gap-2 rounded-2xl px-2.5 py-2">
      <span className="chunky tone-green outline-text grid h-9 w-9 place-items-center rounded-xl text-base">{level}</span>
      <span className="text-left">
        <span className="block text-xs font-bold">{streak > 0 ? `🔥 ${streak} day${streak > 1 ? 's' : ''}` : 'Level ' + level}</span>
        <span className="tray mt-1 block h-3 w-12 overflow-hidden rounded-full">
          <span className="block h-full rounded-full bg-volt" style={{ width: `${(into / span) * 100}%` }} />
        </span>
      </span>
    </button>
  );
}
