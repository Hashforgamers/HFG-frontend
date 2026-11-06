export type WorldId = 'neon' | 'desert' | 'frozen' | 'cyber' | 'volcanic';
export const WORLD_ORDER: readonly WorldId[] = ['neon', 'desert', 'frozen', 'cyber', 'volcanic'];
export const WORLD_NAMES: Record<WorldId, string> = {
  neon: 'Neon Highway',
  desert: 'Desert Ruins',
  frozen: 'Frozen Fortress',
  cyber: 'Cyber City',
  volcanic: 'Volcanic Core',
};

/** `add` / `mul` grow the army; `sub` / `div` are bad gates that shrink it. */
export type GateOp = { kind: 'add' | 'mul' | 'sub' | 'div'; value: number };

export function isBadGate(op: GateOp): boolean {
  return op.kind === 'sub' || op.kind === 'div';
}

export interface GateDef {
  z: number;
  /** Centre of the gate across the track. */
  x: number;
  width: number;
  op: GateOp;
  /** Moving gate: slides `moveAmp` metres either side of `x`. */
  moveAmp?: number;
  moveSpeed?: number;
}

export type EnemyKind = 'grunt' | 'brute' | 'giant' | 'turret';

export interface WaveDef {
  z: number;
  x: number;
  kind: EnemyKind;
  count: number;
}

export type ObstacleDef =
  | { kind: 'movingWall'; z: number; width: number; amp: number; speed: number; phase?: number }
  | { kind: 'blade'; z: number; x: number; radius: number; speed: number }
  | { kind: 'crusher'; z: number; x: number; width: number; depth: number; period: number; phase?: number }
  | { kind: 'laser'; z: number; x0: number; x1: number; period: number; phase?: number }
  | { kind: 'bridge'; z0: number; z1: number; x0: number; x1: number }
  | { kind: 'fallingPlatform'; z0: number; z1: number; x0: number; x1: number }
  | { kind: 'barrel'; z: number; x: number };

export type BossKind = 'titan' | 'inferno' | 'void';

export interface BossDef {
  kind: BossKind;
  hp: number;
  /** Multiplies the boss's attack damage and shortens its attack interval. */
  tier: number;
}

export interface LevelConfig {
  id: number;
  name: string;
  world: WorldId;
  /** Distance from the start line to the boss, metres. */
  length: number;
  gates: GateDef[];
  waves: WaveDef[];
  obstacles: ObstacleDef[];
  boss: BossDef;
  enemyHpScale: number;
  enemyDmgScale: number;
  /** Seconds; finishing faster earns a time bonus. */
  parTime: number;
  reward: { credits: number };
  seed: number;
}

export function gateLabel(op: GateOp): string {
  return { add: '+', mul: '×', sub: '−', div: '÷' }[op.kind] + op.value;
}
