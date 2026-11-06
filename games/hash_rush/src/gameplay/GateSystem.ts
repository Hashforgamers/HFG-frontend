import type { GateDef } from '../levels/LevelConfig';
import { AgentState, CrowdSystem, type Lane } from './CrowdSystem';
import { FX, FxQueue, SPAWN_BUDGET } from './constants';

/** Seconds an additive gate needs to recharge after paying out. */
export const ADD_GATE_COOLDOWN = 2.5;

export interface GateRuntime {
  def: GateDef;
  x: number;
  /** >0 while an additive gate recharges. */
  cooldown: number;
  /** Decays from 1 after each activation (for the view). */
  flash: number;
  /** Units this gate has produced. */
  produced: number;
  activations: number;
  /** Units a bad gate has destroyed. */
  lost: number;
  /** ÷k remainder carried between agents, so exactly 1/k of everything that passes survives. */
  carry: number;
}

/**
 * Gate rules (see docs/GAMEPLAY_RULES.md):
 *  - ×k gates multiply every unit that walks through: an agent of strength s
 *    yields s·(k−1) extra units.
 *  - +n gates pay a flat n units when a unit walks through, then recharge for
 *    ADD_GATE_COOLDOWN seconds. (Paying +n per unit would make "+10" a ×11.)
 *  - Output is clipped by the population cap; the clipped amount is reported,
 *    never hidden.
 *  - ÷k gates (bad) keep one unit in every k that walk through.
 *  - −n gates (bad) destroy a flat n units, then recharge like +n gates.
 * Returns the change in army size (negative for bad gates).
 */
export function applyGate(gate: GateRuntime, crowd: CrowdSystem, agent: number, fx: FxQueue): number {
  const op = gate.def.op;
  const z = gate.def.z + 0.35;
  if (op.kind === 'div' || op.kind === 'sub') {
    let removed: number;
    if (op.kind === 'div') {
      const total = crowd.str[agent]! + gate.carry;
      const keep = Math.floor(total / op.value);
      gate.carry = total % op.value;
      removed = crowd.removeUnits(agent, crowd.str[agent]! - keep, fx);
    } else {
      if (gate.cooldown > 0) return 0;
      gate.cooldown = ADD_GATE_COOLDOWN;
      removed = crowd.removeAny(agent, op.value, fx);
    }
    gate.flash = 1;
    gate.lost += removed;
    if (removed > 0) fx.push(FX.GateLoss, gate.x, gate.def.z, removed);
    return -removed;
  }
  let want: number;
  if (op.kind === 'mul') {
    want = crowd.str[agent]! * (op.value - 1);
  } else {
    if (gate.cooldown > 0) return 0;
    want = op.value;
    gate.cooldown = ADD_GATE_COOLDOWN;
  }
  const added = crowd.add(crowd.x[agent]!, z, want, SPAWN_BUDGET, agent);
  gate.flash = 1;
  gate.produced += added;
  gate.activations++;
  if (added > 0) fx.push(op.kind === 'mul' ? FX.GateMul : FX.GateAdd, crowd.x[agent]!, gate.def.z, added);
  if (added < want) fx.push(FX.GateCapped, gate.x, gate.def.z, want - added);
  return added;
}

export class GateSystem {
  readonly gates: GateRuntime[];
  /**
   * One funnel per gate: when the cannon is lined up with a gate, the whole army
   * squeezes through it. This is what makes a gate a choice — without it a wide
   * army would spill into the neighbouring (possibly bad) gate no matter how you steer.
   */
  readonly lanes: Lane[];
  activations = 0;
  time = 0;

  constructor(defs: readonly GateDef[]) {
    this.gates = defs.map((def) => ({ def, x: def.x, cooldown: 0, flash: 0, produced: 0, activations: 0, lost: 0, carry: 0 }));
    this.lanes = defs.map((def) => ({ z0: def.z, z1: def.z + 0.6, x0: def.x - def.width / 2, x1: def.x + def.width / 2 }));
  }

  /** Is (x) inside the gate, and did the mover cross its plane this tick? */
  static crossed(gate: GateRuntime, x: number, prevZ: number, z: number): boolean {
    return prevZ < gate.def.z && z >= gate.def.z && Math.abs(x - gate.x) <= gate.def.width / 2;
  }

  update(dt: number, crowd: CrowdSystem, fx: FxQueue, zMin: number, zMax: number): void {
    this.time += dt;
    for (let g = 0; g < this.gates.length; g++) {
      const gate = this.gates[g]!;
      const def = gate.def;
      if (def.moveAmp) {
        gate.x = def.x + Math.sin(this.time * (def.moveSpeed ?? 1)) * def.moveAmp;
        const lane = this.lanes[g]!;
        lane.x0 = gate.x - def.width / 2;
        lane.x1 = gate.x + def.width / 2;
      }
      if (gate.cooldown > 0) gate.cooldown = Math.max(0, gate.cooldown - dt);
      if (gate.flash > 0) gate.flash = Math.max(0, gate.flash - dt * 3);
      if (def.z < zMin || def.z > zMax) continue;
      for (let i = 0; i < crowd.cap; i++) {
        const s = crowd.state[i];
        if (s !== AgentState.Run && s !== AgentState.Fight) continue;
        if (!GateSystem.crossed(gate, crowd.x[i]!, crowd.pz[i]!, crowd.z[i]!)) continue;
        // only gates that helped count towards the score
        if (applyGate(gate, crowd, i, fx) > 0) this.activations++;
      }
    }
  }
}
