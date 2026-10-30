import { forwardRef, type ReactNode } from 'react';

/** Square play field for the tap games; positions inside are 0–1 on both axes. */
export const Field = forwardRef<HTMLDivElement, { children?: ReactNode; onTap?: (x: number, y: number) => void; label: string }>(
  function Field({ children, onTap, label }, ref) {
    return (
      <div
        ref={ref}
        role="application"
        aria-label={label}
        onPointerDown={(e) => {
          if (!onTap || e.button !== 0) return;
          e.preventDefault();
          const box = e.currentTarget.getBoundingClientRect();
          onTap((e.clientX - box.left) / box.width, (e.clientY - box.top) / box.height);
        }}
        className="tray relative mx-auto aspect-square w-full max-w-[min(100%,60vh)] touch-none overflow-hidden rounded-3xl"
      >
        {children}
      </div>
    );
  },
);

/** A round chunky target drawn at field position x, y with diameter d (all 0–1). */
export function Dot({ x, y, d, tone = 'tone-green', children, style }: {
  x: number;
  y: number;
  d: number;
  tone?: string;
  children?: ReactNode;
  style?: React.CSSProperties;
}) {
  return (
    <span
      className={`chunky ${tone} outline-text pointer-events-none absolute grid -translate-x-1/2 -translate-y-1/2 place-items-center rounded-full`}
      style={{ left: `${x * 100}%`, top: `${y * 100}%`, width: `${d * 100}%`, height: `${d * 100}%`, ...style }}
    >
      {children}
    </span>
  );
}
