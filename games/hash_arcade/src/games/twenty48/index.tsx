import { useEffect, useRef, useState } from 'react';
import type { GameProps } from '../../engine/types';
import { N, addTile, canMove, move, newBoard, type Dir } from './logic';

const TILE: Record<number, string> = {
  2: 'tone-purple', 4: 'tone-purple', 8: 'tone-green', 16: 'tone-green', 32: 'tone-yellow', 64: 'tone-yellow', 128: 'tone-red', 256: 'tone-red',
};

export default function Twenty48({ ctx }: GameProps) {
  const [board, setBoard] = useState(() => newBoard(ctx.rng));
  const startPt = useRef<{ x: number; y: number } | null>(null);

  const go = (dir: Dir) => {
    const r = move(board, dir);
    if (!r.moved) return;
    const next = addTile(r.board, ctx.rng);
    setBoard(next);
    if (r.points) ctx.hit(r.points);
    ctx.stat('Best tile', Math.max(...next));
    if (!canMove(next)) ctx.finish();
  };

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const d = ({ ArrowLeft: 'left', ArrowRight: 'right', ArrowUp: 'up', ArrowDown: 'down' } as Record<string, Dir>)[e.key];
      if (d) {
        e.preventDefault();
        go(d);
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  });

  return (
    <div className="mx-auto flex h-full max-w-md flex-col items-center justify-center gap-4">
      <p className="text-sm tracking-widest text-soft">SWIPE TO MERGE MATCHING TILES</p>
      <div
        role="application"
        aria-label="2048 board. Swipe or use arrow keys."
        onPointerDown={(e) => (startPt.current = { x: e.clientX, y: e.clientY })}
        onPointerUp={(e) => {
          const s = startPt.current;
          startPt.current = null;
          if (!s) return;
          const dx = e.clientX - s.x, dy = e.clientY - s.y;
          if (Math.max(Math.abs(dx), Math.abs(dy)) < 24) return;
          go(Math.abs(dx) > Math.abs(dy) ? (dx > 0 ? 'right' : 'left') : dy > 0 ? 'down' : 'up');
        }}
        className="tray grid aspect-square w-full max-w-[min(100%,52vh)] touch-none gap-2 rounded-3xl p-2"
        style={{ gridTemplateColumns: `repeat(${N}, 1fr)`, gridTemplateRows: `repeat(${N}, 1fr)` }}
      >
        {board.map((v, i) => (
          <div key={i} className={`grid place-items-center rounded-2xl ${v ? `chunky ${TILE[v] ?? 'tone-red'}` : 'bg-black/20'}`}>
            {v > 0 && <span className={`outline-text ${v >= 1000 ? 'text-xl' : v >= 100 ? 'text-2xl' : 'text-3xl'}`}>{v}</span>}
          </div>
        ))}
      </div>
      <div className="grid grid-cols-4 gap-2">
        {(['left', 'up', 'down', 'right'] as Dir[]).map((d) => (
          <button key={d} onClick={() => go(d)} aria-label={`Move ${d}`} className="chunky tone-purple outline-text h-12 w-14 rounded-2xl text-2xl">
            {{ left: '←', up: '↑', down: '↓', right: '→' }[d]}
          </button>
        ))}
      </div>
    </div>
  );
}
