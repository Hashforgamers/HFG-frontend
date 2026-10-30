import { describe, expect, it } from 'vitest';
import { gridSize, hashString, makePuzzle, mulberry32, multiplier, rankFor, tierFor } from '../src/game';

describe('odd one out rules', () => {
  it('tiers follow the level bands', () => {
    expect([1, 5, 6, 10, 11, 20, 21, 99].map(tierFor)).toEqual(
      ['EASY', 'EASY', 'MEDIUM', 'MEDIUM', 'HARD', 'HARD', 'INSANE', 'INSANE'],
    );
  });

  it('every puzzle has exactly one odd cell, in range, different from the rest', () => {
    const rng = mulberry32(1);
    for (let level = 1; level < 60; level++) {
      for (const [mc, mr] of [[99, 99], [11, 14], [4, 4]]) {
        const p = makePuzzle(level, rng, mc, mr);
        expect(p.odd).not.toBe(p.base);
        expect(p.oddIndex).toBeGreaterThanOrEqual(0);
        expect(p.oddIndex).toBeLessThan(p.rows * p.cols);
        expect(p.cols).toBeLessThanOrEqual(Math.max(4, Math.min(gridSize(level), mc)));
      }
    }
  });

  it('adds rows and columns as levels climb', () => {
    expect([1, 2, 3, 10, 20, 30, 99].map(gridSize)).toEqual([6, 6, 7, 10, 15, 20, 20]);
    const p = makePuzzle(25, Math.random);
    expect([p.cols, p.rows]).toEqual([18, 18]);
  });

  it('daily sequence is deterministic for a date', () => {
    const seq = (d: string) => {
      const rng = mulberry32(hashString(d));
      return Array.from({ length: 30 }, (_, i) => makePuzzle(i + 1, rng, 10, 12));
    };
    expect(seq('2026-10-30')).toEqual(seq('2026-10-30'));
    expect(seq('2026-10-30')).not.toEqual(seq('2026-10-31'));
  });

  it('multiplier climbs every 3 hits and caps at 5', () => {
    expect([0, 1, 2, 3, 6, 9, 12, 100].map(multiplier)).toEqual([1, 1, 1, 2, 3, 4, 5, 5]);
  });

  it('ranks by score', () => {
    expect(rankFor(0).title).toBe('ROOKIE');
    expect(rankFor(9999).title).toBe('LEGEND');
  });
});
