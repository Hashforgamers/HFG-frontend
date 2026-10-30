import { describe, expect, it } from 'vitest';
import { mulberry32 } from '../src/engine/rng';
import { sizeFor as rrSize, spawn, within } from '../src/games/reflex_rush/logic';
import { hitPoints, place, sizeFor as aimSize } from '../src/games/aim_trainer/logic';
import { SIZE, bubble, type Bubble } from '../src/games/tap_frenzy/logic';
import { nextPop } from '../src/games/whack_mole/logic';
import { hitsPlayer, makeRow } from '../src/games/dodge_rush/logic';
import { drawPoints, makeSignals } from '../src/games/quick_draw/logic';
import { RADIUS, mover, step } from '../src/games/moving_target/logic';
import { judge, makeChart } from '../src/games/rhythm_tap/logic';
import { countSolutions, makeSudoku, solvedSudoku, valid } from '../src/games/mini_sudoku/logic';
import { canMove, move, slideRow } from '../src/games/twenty48/logic';
import { cleared, layMines, layoutFor, neighbours, reveal } from '../src/games/minesweeper/logic';
import { clue, makeNonogram, matchesClues } from '../src/games/nonogram/logic';
import { isSolved, shuffled, slide, slidable, solvedBoard } from '../src/games/sliding_puzzle/logic';
import { score } from '../src/games/mastermind/logic';
import { canMove as hanoiCan, done, moveDisk, start } from '../src/games/hanoi/logic';
import { makeFlow, solvedFlow } from '../src/games/connect_dots/logic';
import { clueText, makeLogic, solutions } from '../src/games/logic_grid/logic';
import { COMMON_WORDS, VALID_WORDS } from '../src/games/_shared/dictionary';
import { CATEGORIES } from '../src/games/_shared/categories';
import { isWord, spellable } from '../src/games/_shared/words.helpers';
import { acceptScramble, makeScramble } from '../src/games/word_scramble/logic';
import { lineBetween, makeSearch, wordAt } from '../src/games/word_search/logic';
import { legalStep, makeLadder, oneApart } from '../src/games/word_ladder/logic';
import { nextWord, wpm } from '../src/games/typing_sprint/logic';
import { acceptGap, makeGap } from '../src/games/missing_letter/logic';
import { makeRack } from '../src/games/anagram_rush/logic';
import { markGuess } from '../src/games/five_letter/logic';
import { categoryFor, makePrompt } from '../src/games/category_rush/logic';
import { makeSpell } from '../src/games/spelling_blitz/logic';
import { judgeLink, startWord } from '../src/games/word_chain/logic';
import { GAMES as ALL_GAMES } from '../src/games/registry';

const LEVELS = Array.from({ length: 20 }, (_, i) => i + 1);
const rng = mulberry32(99);

describe('reflex games', () => {
  it('targets stay fully on the field', () => {
    for (const l of LEVELS) {
      const t = spawn(l, rng);
      const r = rrSize(l) / 2;
      expect(t.x - r).toBeGreaterThanOrEqual(0);
      expect(t.x + r).toBeLessThanOrEqual(1);
      expect(within(t.x, t.y, t, r)).toBe(true);
      const a = place(l, rng);
      expect(a.y + aimSize(l) / 2).toBeLessThanOrEqual(1);
    }
    expect(hitPoints(0)).toBe(200);
    expect(hitPoints(5000)).toBe(30);
  });
  it('tap frenzy bubbles do not overlap', () => {
    const b: Bubble[] = [];
    while (b.length < 5) b.push(bubble(rng, b));
    for (let i = 0; i < 5; i++) for (let j = i + 1; j < 5; j++) expect(Math.hypot(b[i].x - b[j].x, b[i].y - b[j].y)).toBeGreaterThan(SIZE);
  });
  it('whack-a-mole never pops the same hole twice running, no decoys early', () => {
    let last = -1;
    for (let i = 0; i < 200; i++) {
      const p = nextPop(2, rng, last);
      expect(p.hole).not.toBe(last);
      expect(p.decoy).toBe(false);
      last = p.hole;
    }
  });
  it('dodge rows always leave a free lane, collisions only in the player row', () => {
    for (const l of LEVELS) for (const lanes of [3, 4]) expect(makeRow(lanes, l, rng).length).toBeLessThan(lanes);
    expect(hitsPlayer(0.86, [1], 1)).toBe(true);
    expect(hitsPlayer(0.86, [1], 0)).toBe(false);
    expect(hitsPlayer(0.3, [1], 1)).toBe(false);
  });
  it('quick draw always ends on DRAW! and penalises guesses', () => {
    for (let r = 0; r < 8; r++) {
      const s = makeSignals(r, rng);
      expect(s[s.length - 1]).toBe('DRAW!');
      expect(s.slice(0, -1)).not.toContain('DRAW!');
    }
    expect(drawPoints(50)).toBe(0);
    expect(drawPoints(200)).toBeGreaterThan(drawPoints(400));
  });
  it('moving targets bounce inside the walls', () => {
    let m = mover(10, rng);
    for (let i = 0; i < 1000; i++) {
      m = step(m, 0.05);
      expect(m.x).toBeGreaterThanOrEqual(RADIUS);
      expect(m.x).toBeLessThanOrEqual(1 - RADIUS);
      expect(m.y).toBeGreaterThanOrEqual(RADIUS);
    }
  });
  it('rhythm chart is ordered with real gaps; judging windows', () => {
    const c = makeChart(rng);
    const gaps = c.notes.slice(1).map((v, i) => v - c.notes[i]);
    expect(Math.min(...gaps)).toBeGreaterThanOrEqual(299);
    expect([judge(10), judge(-100), judge(300)]).toEqual(['perfect', 'good', 'miss']);
  });
});

describe('logic games', () => {
  it('mini sudoku: unique solution, givens agree with it', () => {
    for (const l of [1, 3, 5, 8]) {
      const s = makeSudoku(l, rng);
      expect(countSolutions([...s.givens], s.n, s.boxW, s.boxH)).toBe(1);
      s.givens.forEach((v, i) => v && expect(v).toBe(s.solution[i]));
      expect(s.givens.filter((v) => v === 0).length).toBeGreaterThan(3);
      expect(solvedSudoku(s, s.solution)).toBe(true);
      s.solution.forEach((v, i) => {
        const g = [...s.solution];
        g[i] = 0;
        expect(valid(g, s.n, s.boxW, s.boxH, i, v)).toBe(true);
      });
    }
  });
  it('2048 merges each pair once and detects a stuck board', () => {
    expect(slideRow([2, 2, 2, 2])).toEqual({ row: [4, 4, 0, 0], points: 8 });
    expect(slideRow([4, 0, 4, 8])).toEqual({ row: [8, 8, 0, 0], points: 8 });
    expect(move([2, 0, 0, 2, ...Array(12).fill(0)], 'right').board.slice(0, 4)).toEqual([0, 0, 0, 4]);
    expect(canMove([2, 4, 2, 4, 4, 2, 4, 2, 2, 4, 2, 4, 4, 2, 4, 2])).toBe(false);
  });
  it('minesweeper: first tap and its neighbours are always safe; flood opens zeros', () => {
    for (const l of [1, 4, 7]) {
      const { cols, rows, mines } = layoutFor(l);
      const first = Math.floor((cols * rows) / 2);
      const m = layMines(l, first, rng);
      expect(m.filter(Boolean)).toHaveLength(mines);
      [first, ...neighbours(first, cols, rows)].forEach((i) => expect(m[i]).toBe(false));
      const open = reveal(m, Array(cols * rows).fill(false), first, cols, rows);
      expect(open.filter(Boolean).length).toBeGreaterThan(1);
      expect(open.some((o, i) => o && m[i])).toBe(false);
      expect(cleared(m, m.map((x) => !x))).toBe(true);
    }
  });
  it('nonogram clues', () => {
    expect(clue([true, true, false, true])).toEqual([2, 1]);
    expect(clue([false, false])).toEqual([0]);
    for (const l of LEVELS) {
      const p = makeNonogram(l, rng);
      expect(matchesClues(p, p.picture)).toBe(true);
    }
  });
  it('sliding puzzle shuffles are scrambled and only legal slides move', () => {
    for (const l of LEVELS) expect(isSolved(shuffled(l, rng))).toBe(false);
    const b = solvedBoard(3);
    expect(slidable(b, 3, 7)).toBe(true);
    expect(slidable(b, 3, 0)).toBe(false);
    expect(slide(b, 3, 0)).toBe(b);
  });
  it('mastermind scoring counts duplicates once', () => {
    expect(score([0, 1, 2, 3], [0, 1, 2, 3])).toEqual({ exact: 4, near: 0 });
    expect(score([0, 0, 1, 1], [1, 1, 0, 0])).toEqual({ exact: 0, near: 4 });
    expect(score([0, 1, 1, 2], [1, 1, 1, 1])).toEqual({ exact: 2, near: 0 });
    expect(score([0, 1, 2, 3], [3, 3, 3, 3])).toEqual({ exact: 1, near: 0 });
  });
  it('hanoi forbids big on small and solves in 2^n − 1', () => {
    let p = start(3);
    expect(hanoiCan(p, 0, 1)).toBe(true);
    p = moveDisk(p, 0, 2);
    expect(hanoiCan(p, 0, 2)).toBe(false);
    const solve = (n: number, a: number, b: number, c: number): [number, number][] =>
      n === 0 ? [] : [...solve(n - 1, a, c, b), [a, c], ...solve(n - 1, b, a, c)];
    let q = start(4);
    for (const [f, t] of solve(4, 0, 1, 2)) q = moveDisk(q, f, t);
    expect(done(q, 4)).toBe(true);
  });
  it('connect the dots: planted routes are a valid solution', () => {
    for (const l of LEVELS) {
      const f = makeFlow(l, rng);
      expect(solvedFlow(f, f.routes)).toBe(true);
      expect(new Set(f.routes.flat()).size).toBe(f.routes.flat().length);
    }
  });
  it('logic grid has exactly one answer and readable clues', () => {
    for (const l of [1, 3, 5, 9]) {
      const p = makeLogic(l, rng);
      const s = solutions(p.n, p.clues);
      expect(s).toHaveLength(1);
      expect(s[0]).toEqual(p.solution);
      p.clues.forEach((c) => expect(clueText(c)).toMatch(/^[A-Z]/));
    }
  });
});

describe('word games', () => {
  it('dictionary: everyday words are all valid, no blocked words as answers', () => {
    expect(COMMON_WORDS.length).toBeGreaterThan(4000);
    for (const w of COMMON_WORDS) expect(VALID_WORDS.has(w)).toBe(true);
    for (const bad of ['shit', 'fuck', 'bitch', 'rape']) expect(COMMON_WORDS).not.toContain(bad);
    expect(isWord('Plant')).toBe(true);
    expect(spellable('tea', 'eat')).toBe(true);
    expect(spellable('teat', 'eat')).toBe(false);
  });
  it('scramble is never already solved and accepts real anagrams', () => {
    for (const l of LEVELS) {
      const r = makeScramble(l, rng);
      if (new Set(r.word).size > 1) expect(r.letters.join('')).not.toBe(r.word);
      expect(acceptScramble(r.word, r.word)).toBe(true);
    }
    expect(acceptScramble('tea', 'eat')).toBe(true);
    expect(acceptScramble('tea', 'aet')).toBe(false);
  });
  it('word search: every word is where it says, selectable by its line', () => {
    for (const l of LEVELS.slice(0, 10)) {
      const ws = makeSearch(l, rng);
      ws.words.forEach((w, k) => {
        expect(ws.places[k].map((i) => ws.grid[i]).join('')).toBe(w);
        const p = ws.places[k];
        expect(lineBetween(p[0], p[p.length - 1], ws.n)).toEqual(p);
        expect(wordAt(ws, [...p].reverse())).toBe(k);
      });
    }
    expect(lineBetween(0, 6, 4)).toBeNull(); // (0,0) to (1,2) is not a straight line
    expect(lineBetween(0, 5, 4)).toEqual([0, 5]); // diagonal
  });
  it('word ladder: target is reachable and the best route is legal', () => {
    for (const l of LEVELS.slice(0, 8)) {
      const lad = makeLadder(l, rng);
      expect(lad.best[0]).toBe(lad.start);
      expect(lad.best[lad.best.length - 1]).toBe(lad.end);
      for (let i = 1; i < lad.best.length; i++) expect(legalStep(lad.best[i - 1], lad.best[i])).toBe(true);
    }
    expect(oneApart('cat', 'cot')).toBe(true);
    expect(oneApart('cat', 'dog')).toBe(false);
  });
  it('typing sprint words and WPM', () => {
    for (let i = 0; i < 30; i++) expect(nextWord(i, rng)).toMatch(/^[a-z]{3,7}$/);
    expect(wpm(250, 60000)).toBe(50);
  });
  it('missing letter accepts the word and other real fits', () => {
    for (const l of LEVELS) {
      const g = makeGap(l, rng);
      expect(acceptGap(g, g.holes.map((h) => g.word[h]))).toBe(true);
    }
    expect(acceptGap({ word: 'cat', holes: [1] }, ['u'])).toBe(true); // cut
    expect(acceptGap({ word: 'cat', holes: [1] }, ['x'])).toBe(false);
  });
  it('anagram racks have plenty of answers, all spellable', () => {
    const r = makeRack(rng);
    expect(r.answers.length).toBeGreaterThanOrEqual(12);
    r.answers.forEach((w) => expect(spellable(w, r.letters.join(''))).toBe(true));
  });
  it('five-letter marks handle repeated letters', () => {
    expect(markGuess('apple', 'apple')).toEqual(['hit', 'hit', 'hit', 'hit', 'hit']);
    expect(markGuess('apple', 'paper')).toEqual(['near', 'near', 'hit', 'near', 'miss']);
    expect(markGuess('abbey', 'bobby')).toEqual(['near', 'miss', 'hit', 'miss', 'hit']);
    expect(markGuess('crane', 'eerie')).toEqual(['miss', 'miss', 'near', 'miss', 'hit']);
  });
  it('category words sit in exactly one category, prompts are honest', () => {
    const all = Object.values(CATEGORIES).flat();
    expect(new Set(all).size).toBe(all.length);
    let cat = categoryFor(0, rng);
    for (let n = 0; n < 60; n++) {
      const p = makePrompt(rng, cat);
      expect(CATEGORIES[cat].includes(p.word)).toBe(p.belongs);
      cat = categoryFor(n + 1, rng, cat);
    }
  });
  it('spelling blitz: one real spelling, two fake ones', () => {
    for (const l of LEVELS) {
      const q = makeSpell(l, rng);
      expect(new Set(q.options).size).toBe(3);
      expect(q.options).toContain(q.word);
      q.options.filter((o) => o !== q.word).forEach((o) => expect(isWord(o)).toBe(false));
    }
  });
  it('word chain rules', () => {
    expect(judgeLink('apple', 'egg', new Set())).toBe('ok');
    expect(judgeLink('apple', 'arm', new Set())).toBe('wrong-start');
    expect(judgeLink('apple', 'eqz', new Set())).toBe('not-a-word');
    expect(judgeLink('apple', 'egg', new Set(['egg']))).toBe('used');
    expect(startWord(rng)).toMatch(/^[a-z]{4,7}$/);
  });
});

describe('catalogue', () => {
  it('all 60 games are playable with rules', () => {
    expect(ALL_GAMES.filter((g) => g.load)).toHaveLength(60);
    ALL_GAMES.forEach((g) => expect(g.howTo.length).toBeGreaterThan(0));
  });
});
