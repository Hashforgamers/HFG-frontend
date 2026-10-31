// Flat SVG shapes for the observation games. Same look on every device, unlike emoji.
export const SHAPES = ['circle', 'square', 'triangle', 'diamond', 'star', 'hexagon', 'cross', 'heart'] as const;
export type Shape = (typeof SHAPES)[number];

export const PALETTE = ['#7cf06b', '#ffe45c', '#ff6f61', '#2e9bff', '#ff77ae', '#b9a8ff'] as const;
export const COLOR_NAMES: Record<string, string> = {
  '#7cf06b': 'green', '#ffe45c': 'yellow', '#ff6f61': 'red', '#2e9bff': 'blue', '#ff77ae': 'pink', '#b9a8ff': 'lilac',
};

const PATHS: Record<Shape, string> = {
  circle: 'M50 8a42 42 0 1 0 0.01 0z',
  square: 'M12 12h76v76H12z',
  triangle: 'M50 8 92 88H8z',
  diamond: 'M50 4 94 50 50 96 6 50z',
  star: 'M50 5l13 28 30 3-23 20 7 30-27-16-27 16 7-30L7 36l30-3z',
  hexagon: 'M27 8h46l23 42-23 42H27L4 50z',
  cross: 'M36 6h28v30h30v28H64v30H36V64H6V36h30z',
  heart: 'M50 90 12 52C-6 32 14 2 38 16l12 10 12-10c24-14 44 16 26 36z',
};

export function ShapeSvg({ shape, color, rotate = 0, size = '100%', label }: {
  shape: Shape;
  color: string;
  rotate?: number;
  size?: string | number;
  label?: string;
}) {
  return (
    <svg viewBox="0 0 100 100" width={size} height={size} role={label ? 'img' : undefined} aria-label={label} aria-hidden={label ? undefined : true}>
      <path
        d={PATHS[shape]}
        fill={color}
        stroke="#0b0b10"
        strokeWidth={6}
        strokeLinejoin="round"
        transform={rotate ? `rotate(${rotate} 50 50)` : undefined}
      />
    </svg>
  );
}
