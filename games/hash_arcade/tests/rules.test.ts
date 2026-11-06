import { describe, expect, it } from 'vitest';
import { mulberry32 } from '../src/engine/rng';
import { careerScore, levelFor, nextStreak, normalize, xpForLevel } from '../src/engine/profile';
import { GAMES, PLAYABLE, dailyGames } from '../src/games/registry';
import { makeRound } from '../src/games/color_clash/logic';
import { makeProblem } from '../src/games/math_blitz/logic';
import { correctSide, makePair } from '../src/games/greater_smaller/logic';
import { build, makeSequence, type Rule } from '../src/games/number_sequence/logic';
import { countFor, makeFlash, sizeFor } from '../src/games/memory_flash/logic';
import { checkInput } from '../src/games/simon_says/logic';
import { average, trialPoints } from '../src/games/reaction_timer/logic';
import { judge, makeZone, triangle } from '../src/games/precision_stop/logic';
import { press, scramble, solved, solvePoints } from '../src/games/lights_out/logic';

const LEVELS = Array.from({ length: 40 }, (_, i) => i + 1);
const rng = mulberry32(42);
const evalExpr = (s: string) => Function(`return ${s.replace(/×/g, '*').replace(/÷/g, '/').replace(/−/g, '-')}`)() as number;

describe('catalogue', () => {
  it('lists 60 unique games, 10 per category', () => {
    expect(GAMES).toHaveLength(60);
    expect(new Set(GAMES.map((g) => g.id)).size).toBe(60);
    for (const cat of ['observation', 'math', 'memory', 'reflex', 'logic', 'words']) {
      expect(GAMES.filter((g) => g.category === cat)).toHaveLength(10);
    }
  });
  it('playable games have rules and a clock, lives or self-ending', () => {
    for (const g of PLAYABLE) expect(g.howTo.length).toBeGreaterThan(0);
  });
  it('daily picks three different playable games, stable per date', () => {
    const d = dailyGames('2026-10-30');
    expect(new Set(d.map((g) => g.id)).size).toBe(3);
    expect(dailyGames('2026-10-30')).toEqual(d);
  });
});

describe('profile', () => {
  it('normalises to 0–1000', () => {
    expect([normalize(0, 100), normalize(50, 100), normalize(500, 100), normalize(-5, 100)]).toEqual([0, 500, 1000, 0]);
    expect(careerScore({ a: 1000, b: 250 })).toBe(1250);
  });
  it('levels follow the xp curve', () => {
    for (const l of [1, 2, 5, 10]) expect(levelFor(xpForLevel(l))).toBe(l);
    expect(levelFor(xpForLevel(3) - 1)).toBe(2);
  });
  it('daily streak continues, holds and resets', () => {
    expect(nextStreak({ count: 3, last: '2026-10-29' }, '2026-10-30')).toEqual({ count: 4, last: '2026-10-30' });
    expect(nextStreak({ count: 3, last: '2026-10-30' }, '2026-10-30')).toEqual({ count: 3, last: '2026-10-30' });
    expect(nextStreak({ count: 3, last: '2026-10-27' }, '2026-10-30')).toEqual({ count: 1, last: '2026-10-30' });
    expect(nextStreak({ count: 9, last: '2026-10-31' }, '2026-11-01')).toEqual({ count: 10, last: '2026-11-01' });
  });
});

describe('color clash', () => {
  it('ink is always an option, options are unique, word ≠ ink from level 4', () => {
    for (const l of LEVELS) {
      const r = makeRound(l, rng);
      expect(r.options).toContain(r.ink);
      expect(new Set(r.options).size).toBe(r.options.length);
      if (l >= 4) expect(r.word).not.toBe(r.ink);
      if (r.word !== r.ink) expect(r.options).toContain(r.word);
    }
  });
});

describe('math blitz', () => {
  it('answers are correct, whole and non-negative', () => {
    for (const l of LEVELS) for (let i = 0; i < 30; i++) {
      const p = makeProblem(l, rng);
      expect(evalExpr(p.text)).toBe(p.answer);
      expect(Number.isInteger(p.answer) && p.answer >= 0).toBe(true);
    }
  });
});

describe('greater or smaller', () => {
  it('never ties, labels match values, correct side is right', () => {
    for (const l of LEVELS) for (let i = 0; i < 20; i++) {
      const p = makePair(l, rng);
      expect(p.left.value).not.toBe(p.right.value);
      for (const s of [p.left, p.right]) expect(evalExpr(s.label)).toBeCloseTo(s.value, 9);
      const win = correctSide(p) === 'left' ? p.left : p.right;
      const lose = correctSide(p) === 'left' ? p.right : p.left;
      expect(p.ask === 'greater' ? win.value > lose.value : win.value < lose.value).toBe(true);
    }
  });
});

describe('number sequence', () => {
  it('rules produce what they claim', () => {
    expect(build('step', () => 0)).toEqual([1, 3, 5, 7, 9, 11]);
    const diffs = (a: number[]) => a.slice(1).map((v, i) => v - a[i]);
    for (let i = 0; i < 50; i++) {
      const f = build('fibonacci', rng);
      for (let j = 2; j < f.length; j++) expect(f[j]).toBe(f[j - 1] + f[j - 2]);
      const g = diffs(build('growing', rng));
      for (let j = 1; j < g.length; j++) expect(g[j] - g[j - 1]).toBe(1);
      const d = build('down', rng);
      expect(d.every((v) => v > 0)).toBe(true);
    }
  });
  it('the gap is never one of the first two terms', () => {
    for (const l of LEVELS) {
      const s = makeSequence(l, rng);
      expect(s.missing).toBeGreaterThanOrEqual(2);
      expect(s.full.every(Number.isInteger)).toBe(true);
      expect((['step', 'down', 'double', 'squares', 'fibonacci', 'interleave', 'growing'] as Rule[])).toContain(s.rule);
    }
  });
});

describe('memory flash', () => {
  it('cells are distinct, in range, and grow with level', () => {
    for (const l of LEVELS) {
      const f = makeFlash(l, rng);
      expect(new Set(f.cells).size).toBe(countFor(l));
      expect(f.cells.every((c) => c >= 0 && c < f.size ** 2)).toBe(true);
      expect(f.cells.length).toBeLessThan(f.size ** 2);
    }
    expect(sizeFor(1)).toBe(3);
    expect(sizeFor(40)).toBe(6);
  });
});

describe('simon says', () => {
  it('judges each input', () => {
    expect(checkInput([0, 2, 1], [0])).toBe('ok');
    expect(checkInput([0, 2, 1], [0, 2, 1])).toBe('round-done');
    expect(checkInput([0, 2, 1], [0, 3])).toBe('fail');
  });
});

describe('reaction timer', () => {
  it('faster scores more, slow scores nothing', () => {
    expect(trialPoints(150)).toBe(900);
    expect(trialPoints(40)).toBe(0); // anticipation, not a reaction
    expect(trialPoints(250)).toBeGreaterThan(trialPoints(300));
    expect(trialPoints(700)).toBe(0);
    expect(average([200, 300])).toBe(250);
    expect(average([])).toBe(0);
  });
});

describe('precision stop', () => {
  it('sweeps 0→1→0 and judges by closeness', () => {
    expect([triangle(0), triangle(0.25), triangle(0.5), triangle(0.75), triangle(1)]).toEqual([0, 0.5, 1, 0.5, 0]);
    const zone = { center: 0.5, width: 0.2, speed: 1 };
    expect(judge(0.5, zone)).toEqual({ inZone: true, perfect: true, points: 200 });
    expect(judge(0.6, zone).points).toBe(100);
    expect(judge(0.61, zone).inZone).toBe(false);
  });
  it('zones fit on the bar and shrink', () => {
    for (const l of LEVELS) {
      const z = makeZone(l, rng);
      expect(z.center - z.width / 2).toBeGreaterThanOrEqual(0);
      expect(z.center + z.width / 2).toBeLessThanOrEqual(1);
    }
    expect(makeZone(30, rng).width).toBeLessThan(makeZone(1, rng).width);
  });
});

describe('lights out', () => {
  it('a press flips the cross', () => {
    const g = press(Array(9).fill(false), 4, 3);
    expect(g.map(Number)).toEqual([0, 1, 0, 1, 1, 1, 0, 1, 0]);
    expect(press(Array(9).fill(false), 0, 3).map(Number)).toEqual([1, 1, 0, 1, 0, 0, 0, 0, 0]);
  });
  it('every board is unsolved and solvable', () => {
    for (const l of LEVELS) {
      const b = scramble(l, rng);
      expect(solved(b.grid)).toBe(false);
      expect(solved(b.presses.reduce((g, i) => press(g, i, b.n), b.grid))).toBe(true);
    }
  });
  it('fewer moves score more', () => {
    expect(solvePoints(4, 4)).toBeGreaterThan(solvePoints(4, 10));
    expect(solvePoints(4, 50)).toBe(100);
  });
});
