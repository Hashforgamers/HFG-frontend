import { careerScore, levelFor, useProfile, xpForLevel } from '../engine/profile';
import { go } from '../engine/router';
import { PLAYABLE } from '../games/registry';
import { Thumb } from '../ui';

export default function Profile() {
  const { xp, plays, bests, normBests, streak } = useProfile();
  const level = levelFor(xp);
  const into = xp - xpForLevel(level);
  const span = xpForLevel(level + 1) - xpForLevel(level);
  const stats: [string, string | number][] = [
    ['Level', level],
    ['Arcade score', careerScore(normBests).toLocaleString()],
    ['Games played', plays],
    ['Daily streak', `${streak.count} 🔥`],
  ];
  return (
    <main className="no-scrollbar h-full overflow-y-auto px-4 pb-[calc(env(safe-area-inset-bottom)+24px)] safe-top">
      <div className="mx-auto max-w-2xl">
        <button onClick={() => go('')} aria-label="Back to arcade" className="web-back clear-back glass grid h-11 w-11 place-items-center rounded-full text-xl">‹</button>
        <h1 className="mt-4 text-3xl font-black">Your profile</h1>

        <div className="glass mt-4 rounded-3xl p-5">
          <div className="flex items-end justify-between">
            <span className="text-5xl font-black text-neon outline-text">LV {level}</span>
            <span className="text-sm text-white/60">{into} / {span} XP</span>
          </div>
          <div className="tray mt-3 h-4 overflow-hidden rounded-full">
            <div className="h-full rounded-full bg-volt" style={{ width: `${(into / span) * 100}%` }} />
          </div>
          <dl className="mt-5 grid grid-cols-2 gap-2.5">
            {stats.map(([k, v]) => (
              <div key={k} className="tray rounded-2xl px-3 py-2.5">
                <dt className="text-[10px] font-bold uppercase tracking-[0.2em] text-white/50">{k}</dt>
                <dd className="text-xl font-black tabular-nums">{v}</dd>
              </div>
            ))}
          </dl>
          <p className="mt-3 text-xs text-white/45">
            Arcade score adds up your best in every game (up to 1,000 each). It's what the Hash app leaderboard ranks.
          </p>
        </div>

        <h2 className="mt-7 text-lg font-black">Personal records</h2>
        <ul className="mt-3 space-y-2">
          {PLAYABLE.map((g) => (
            <li key={g.id}>
              <button onClick={() => go(`play/${g.id}`)} className="glass flex w-full items-center gap-3 rounded-2xl p-2.5 text-left">
                <div className="w-12 shrink-0"><Thumb def={g} /></div>
                <span className="flex-1 font-bold">{g.name}</span>
                <span className="text-right">
                  <span className="block font-black tabular-nums">{bests[g.id]?.toLocaleString() ?? '—'}</span>
                  <span className="block text-[10px] text-white/45">{normBests[g.id] ?? 0}/1000</span>
                </span>
              </button>
            </li>
          ))}
        </ul>
      </div>
    </main>
  );
}
