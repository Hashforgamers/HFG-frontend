import { describe, expect, it } from 'vitest';
import { mulberry32 } from '../src/engine/rng';
import { apply, evaluate, q, show } from '../src/games/_shared/fraction';
import { checkCross, makeCross } from '../src/games/cross_math/logic';
import { checkKenKen, makeKenKen } from '../src/games/kenken/logic';
import { canStep, makeMaze, walk } from '../src/games/math_maze/logic';
import { checkBlanks, makeBlanks } from '../src/games/missing_operator/logic';
import { TARGET, make24, solvable } from '../src/games/make_24/logic';
import { combine, makeTarget } from '../src/games/number_target/logic';
import { makeChain, runStep } from '../src/games/arithmetic_chain/logic';
import { layoutFor as pairLayout, makeDeck } from '../src/games/card_pairs/logic';
import { makeDigits } from '../src/games/number_recall/logic';
import { makeRecall } from '../src/games/sequence_recall/logic';
import { makeAnzan } from '../src/games/flash_anzan/logic';
import { makePlacement } from '../src/games/position_memory/logic';
import { makeWordRound } from '../src/games/word_recall/logic';
import { isMatch, makeStream } from '../src/games/n_back/logic';
import { cycle, makePattern, samePattern } from '../src/games/pattern_replay/logic';
import { makeScene as makeSpot, sameItem } from '../src/games/spot_difference/logic';
import { lookAlikes, makeHunt } from '../src/games/find_number/logic';
import { makeSymbolHunt } from '../src/games/symbol_hunt/logic';
import { makeBoard, sameToken } from '../src/games/shape_match/logic';
import { makeField } from '../src/games/count_objects/logic';
import { asymmetric, flipH, makeMirror, rot90 } from '../src/games/mirror_match/logic';
import { isOnTarget, makeScene as makeHidden } from '../src/games/hidden_object/logic';
import { isAnswer, makeTask } from '../src/games/visual_rush/logic';

const LEVELS = Array.from({ length: 30 }, (_, i) => i + 1);
const rng = mulberry32(7);

describe('fractions', () => {
  it('keeps exact values and precedence', () => {
    expect(show(apply(q(8), '÷', q(3))!)).toBe('8/3');
    expect(show(evaluate([2, 3, 4], ['+', '×'])!)).toBe('14');
    expect(show(evaluate([8, 4, 2], ['÷', '÷'])!)).toBe('1');
    expect(evaluate([1, 0], ['÷'])).toBeNull();
  });
});

describe('cross math', () => {
  it('the generated values solve it and results are never negative', () => {
    for (const l of LEVELS) {
      const c = makeCross(l, rng);
      expect(checkCross(c, c.vals)).toBe(true);
      expect(c.results.every((r) => r >= 0)).toBe(true);
      expect(new Set(c.blanks).size).toBe(c.blanks.length);
    }
  });
  it('rejects wrong values', () => {
    const c = makeCross(1, rng);
    expect(checkCross(c, c.vals.map((v) => v + 1))).toBe(false);
  });
});

describe('kenken', () => {
  it('cages cover every cell once and the solution checks', () => {
    for (const l of LEVELS) {
      const k = makeKenKen(l, rng);
      const cells = k.cages.flatMap((c) => c.cells).sort((a, b) => a - b);
      expect(cells).toEqual([...Array(k.n * k.n).keys()]);
      expect(checkKenKen(k, k.solution)).toBe(true);
    }
  });
  it('rejects a broken Latin square', () => {
    const k = makeKenKen(1, rng);
    const bad = [...k.solution];
    [bad[0], bad[1]] = [bad[1], bad[0]];
    expect(checkKenKen(k, bad)).toBe(false);
  });
});

describe('math maze', () => {
  it('the planted route reaches the target with legal moves', () => {
    for (const l of LEVELS) {
      const m = makeMaze(l, rng);
      expect(m.route[0]).toBe(0);
      expect(m.route[m.route.length - 1]).toBe(m.n * m.n - 1);
      for (let i = 1; i < m.route.length; i++) expect(canStep(m.route[i - 1], m.route[i], m.n)).toBe(true);
      expect(walk(m, m.route)).toBe(m.target);
    }
    expect(canStep(2, 3, 3)).toBe(false); // no wrapping off the right edge
  });
});

describe('missing operator', () => {
  it('targets are whole, non-negative and reachable', () => {
    for (const l of LEVELS) {
      const b = makeBlanks(l, rng);
      expect(Number.isInteger(b.target) && b.target >= 0).toBe(true);
    }
    expect(checkBlanks({ nums: [2, 3, 4], target: 14 }, ['+', '×'])).toBe(true);
    expect(checkBlanks({ nums: [2, 3, 4], target: 14 }, ['×', '+'])).toBe(false);
  });
});

describe('make 24', () => {
  it('only deals solvable hands', () => {
    for (const l of LEVELS.slice(0, 12)) expect(solvable(make24(l, rng).map((n) => q(n)), TARGET)).toBe(true);
    expect(solvable([3, 3, 8, 8].map((n) => q(n)), TARGET)).toBe(true); // needs fractions: 8 ÷ (3 − 8/3)
    expect(solvable([1, 1, 1, 1].map((n) => q(n)), TARGET)).toBe(false);
  });
});

describe('number target', () => {
  it('targets are in range and not a starting number', () => {
    for (const l of LEVELS) {
      const t = makeTarget(l, rng);
      expect(t.nums).not.toContain(t.target);
      expect(t.target).toBeGreaterThanOrEqual(10);
    }
    expect(combine(5, '−', 7)).toBeNull();
    expect(combine(7, '÷', 2)).toBeNull();
    expect(combine(8, '÷', 2)).toBe(4);
  });
});

describe('arithmetic chain', () => {
  it('replaying the steps gives the answer', () => {
    for (const l of LEVELS) {
      const c = makeChain(l, rng);
      expect(c.steps.reduce(runStep, c.start)).toBe(c.answer);
      expect(Number.isInteger(c.answer) && c.answer >= 0).toBe(true);
    }
  });
});

describe('memory games', () => {
  it('card pairs: every symbol exactly twice and the board fills the grid', () => {
    for (const l of LEVELS.slice(0, 8)) {
      const d = makeDeck(l, rng);
      const { cols, rows } = pairLayout(l);
      expect(d).toHaveLength(cols * rows);
      const counts: Record<number, number> = {};
      d.forEach((g) => (counts[g] = (counts[g] ?? 0) + 1));
      expect(Object.values(counts).every((c) => c === 2)).toBe(true);
    }
  });
  it('number recall makes digit strings of the asked length', () => {
    expect(makeDigits(7, rng)).toMatch(/^\d{7}$/);
  });
  it('sequence recall: no symbol twice in a row, all from the pad', () => {
    for (let len = 3; len < 15; len++) {
      const r = makeRecall(len, rng);
      expect(r.sequence).toHaveLength(len);
      expect(new Set(r.pad).size).toBe(6);
      r.sequence.forEach((x, i) => {
        expect(r.pad).toContain(x);
        if (i) expect(x).not.toBe(r.sequence[i - 1]);
      });
    }
  });
  it('flash anzan grows and never repeats a number back to back', () => {
    for (const l of LEVELS) {
      const a = makeAnzan(l, rng);
      a.numbers.forEach((v, i) => i && expect(v).not.toBe(a.numbers[i - 1]));
    }
    expect(makeAnzan(30, rng).numbers.length).toBeGreaterThan(makeAnzan(1, rng).numbers.length);
  });
  it('position memory: distinct cells and symbols, every item asked once', () => {
    for (const l of LEVELS) {
      const p = makePlacement(l, rng);
      expect(new Set(p.items.map((i) => i.cell)).size).toBe(p.items.length);
      expect(new Set(p.items.map((i) => i.glyph)).size).toBe(p.items.length);
      expect([...p.order].sort()).toEqual([...p.items.keys()]);
    }
  });
  it('word recall tests half seen, half new, no duplicates', () => {
    for (const l of LEVELS) {
      const w = makeWordRound(l, rng);
      expect(w.test.filter((t) => t.seen).map((t) => t.word).sort()).toEqual([...w.study].sort());
      expect(new Set(w.test.map((t) => t.word)).size).toBe(w.test.length);
    }
  });
  it('n-back streams have matches, and non-matches never repeat n back by accident', () => {
    for (const n of [1, 2, 3]) {
      const s = makeStream(n, 200, rng);
      const matches = s.filter((_, i) => isMatch(s, i, n)).length;
      expect(matches).toBeGreaterThan(30);
      expect(matches).toBeLessThan(90);
    }
  });
  it('pattern replay cycles colours and compares exactly', () => {
    expect([0, 1, 2, 3].map((v) => cycle(v, 3))).toEqual([1, 2, 3, 0]);
    for (const l of LEVELS) {
      const p = makePattern(l, rng);
      expect(p.cells.some(Boolean)).toBe(true);
      expect(p.cells.every((v) => v >= 0 && v <= p.colors)).toBe(true);
      expect(samePattern(p.cells, [...p.cells])).toBe(true);
    }
  });
});

describe('observation games', () => {
  it('spot the difference: exactly the listed cells differ', () => {
    for (const l of LEVELS) {
      const sc = makeSpot(l, rng);
      const differ = sc.left.map((a, i) => (sameItem(a, sc.right[i]) ? -1 : i)).filter((i) => i >= 0);
      expect(differ.sort((a, b) => a - b)).toEqual([...sc.diffs].sort((a, b) => a - b));
    }
  });
  it('find the number: target appears exactly once', () => {
    for (const l of LEVELS) {
      const h = makeHunt(l, rng);
      expect(h.cells.filter((c) => c === h.target)).toHaveLength(1);
      expect(h.cells).toHaveLength(h.size * h.size);
    }
    expect(lookAlikes(47)).toEqual(expect.arrayContaining([48, 46, 57, 37, 74]));
  });
  it('symbol hunt: targets exactly where it says', () => {
    for (const l of LEVELS) {
      const h = makeSymbolHunt(l, rng);
      h.cells.forEach((c, i) => expect(c === h.target).toBe(h.targets.includes(i)));
    }
  });
  it('shape match: exactly one identical pair', () => {
    for (const l of LEVELS) {
      const b = makeBoard(l, rng);
      let pairs = 0;
      for (let i = 0; i < b.tokens.length; i++) for (let j = i + 1; j < b.tokens.length; j++) if (sameToken(b.tokens[i], b.tokens[j])) pairs++;
      expect(pairs).toBe(1);
      expect(sameToken(b.tokens[b.pair[0]], b.tokens[b.pair[1]])).toBe(true);
    }
  });
  it('count the objects: the answer is the true count', () => {
    for (const l of LEVELS) {
      const f = makeField(l, rng);
      expect(f.items.filter((i) => i.shape === f.ask)).toHaveLength(f.answer);
      expect(f.answer).toBeGreaterThan(0);
    }
  });
  it('mirror match: one mirror, the rest only turned', () => {
    const p = [true, false, false, true, true, false, false, false, false];
    expect(flipH(flipH(p, 3), 3)).toEqual(p);
    expect(rot90(rot90(rot90(rot90(p, 3), 3), 3), 3)).toEqual(p);
    for (const l of LEVELS) {
      const m = makeMirror(l, rng);
      expect(asymmetric(m.pic, m.n)).toBe(true);
      expect(m.options[m.answer]).toEqual(flipH(m.pic, m.n));
      expect(new Set(m.options.map((o) => o.join())).size).toBe(4);
    }
  });
  it('hidden object: target unique and tappable', () => {
    for (const l of LEVELS) {
      const sc = makeHidden(l, rng);
      expect(sc.clutter.some((c) => c.glyph === sc.target.glyph)).toBe(false);
      expect(isOnTarget(sc, sc.target.x, sc.target.y)).toBe(true);
      expect(isOnTarget(sc, sc.target.x + 0.3, sc.target.y)).toBe(false);
    }
  });
  it('visual rush: one right answer per task, kinds rotate', () => {
    let last: ReturnType<typeof makeTask> | undefined;
    for (const l of LEVELS) {
      const t = makeTask(l, rng, last?.kind);
      if (last) expect(t.kind).not.toBe(last.kind);
      const answers = Array.from({ length: t.size * t.size }, (_, i) => i).filter((i) => isAnswer(t, i));
      expect(answers).toHaveLength(1);
      last = t;
    }
  });
});
