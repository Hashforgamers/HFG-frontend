import { useState } from 'react';
import { shake } from '../../ui';
import type { Op } from './fraction';

export interface Card<V> {
  id: number;
  value: V;
}

/**
 * Pick a card, an operator, then another card: the two merge into one.
 * Used by Make 24 (exact fractions) and Number Target (whole numbers only).
 */
export function Combine<V>({ start, combine, label, onMerge, onReset }: {
  start: V[];
  combine: (a: V, op: Op, b: V) => V | null;
  label: (v: V) => string;
  /** Called with the cards left after every merge. */
  onMerge: (cards: Card<V>[]) => void;
  onReset?: () => void;
}) {
  const fresh = () => start.map((value, id) => ({ id, value }));
  const [history, setHistory] = useState<Card<V>[][]>([fresh()]);
  const [sel, setSel] = useState<number | null>(null);
  const [op, setOp] = useState<Op | null>(null);
  const cards = history[history.length - 1];

  const tapCard = (c: Card<V>, el: HTMLElement) => {
    if (sel == null || sel === c.id || !op) {
      setSel(sel === c.id ? null : c.id);
      setOp(null);
      return;
    }
    const a = cards.find((x) => x.id === sel)!;
    const v = combine(a.value, op, c.value);
    if (v == null) {
      shake(el); // not allowed under this game's rules
      return;
    }
    const next = cards.filter((x) => x.id !== a.id).map((x) => (x.id === c.id ? { id: Date.now() + x.id, value: v } : x));
    setHistory([...history, next]);
    setSel(null);
    setOp(null);
    onMerge(next);
  };

  return (
    <div className="flex w-full flex-col items-center gap-5">
      <div className="flex flex-wrap justify-center gap-3">
        {cards.map((c) => (
          <button
            key={c.id}
            onClick={(e) => tapCard(c, e.currentTarget)}
            aria-pressed={sel === c.id}
            className={`chunky outline-text grid h-20 min-w-20 place-items-center rounded-2xl px-3 text-3xl tabular-nums ${sel === c.id ? 'tone-yellow' : 'tone-purple'}`}
          >
            {label(c.value)}
          </button>
        ))}
      </div>
      <div className="flex gap-2">
        {(['+', '−', '×', '÷'] as Op[]).map((o) => (
          <button
            key={o}
            disabled={sel == null}
            onClick={() => setOp(o)}
            aria-pressed={op === o}
            className={`chunky outline-text h-14 w-14 rounded-2xl text-3xl disabled:opacity-40 ${op === o ? 'tone-yellow' : 'tone-green'}`}
          >
            {o}
          </button>
        ))}
      </div>
      <div className="flex gap-3">
        <button
          disabled={history.length < 2}
          onClick={() => { setHistory(history.slice(0, -1)); setSel(null); setOp(null); }}
          className="chunky tone-purple outline-text rounded-2xl px-5 py-2 disabled:opacity-40"
        >
          UNDO
        </button>
        <button
          onClick={() => { setHistory([fresh()]); setSel(null); setOp(null); onReset?.(); }}
          className="chunky tone-purple outline-text rounded-2xl px-5 py-2"
        >
          RESET
        </button>
      </div>
    </div>
  );
}
