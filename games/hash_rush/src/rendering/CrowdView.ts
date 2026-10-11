import * as THREE from 'three';
import type { AssetManager } from '../core/AssetManager';
import { AgentState, agentScale } from '../gameplay/CrowdSystem';
import { ENEMY_STATS, EnemyState } from '../gameplay/EnemySystem';
import type { Simulation } from '../gameplay/Simulation';
import { MAX_AGENTS, MAX_ENEMIES } from '../gameplay/constants';
import type { QualityPreset } from '../optimization/QualityManager';
import { Anim, BotMesh } from './BotMesh';
import type { SkinDef } from '../gameplay/Skins';

const VIEW_BEHIND = 7;
const VIEW_AHEAD = 90;

/** Draws both armies (and turrets, pods, bolts, blob shadows) with a handful of instanced draw calls. */
export class CrowdView {
  readonly group = new THREE.Group();
  private readonly blue: BotMesh;
  private readonly grunt: BotMesh;
  private readonly brute: BotMesh;
  private readonly turret: BotMesh;
  private readonly shadows: THREE.InstancedMesh | null;
  private readonly pods: THREE.InstancedMesh;
  private readonly bolts: THREE.InstancedMesh;
  private readonly dummy = new THREE.Object3D();
  /** Instances drawn last frame (debug overlay). */
  drawn = 0;

  constructor(assets: AssetManager, quality: QualityPreset, skin: SkinDef) {
    const lo = quality.lowPolyCrowd ? '_lo' : '';
    this.blue = new BotMesh(assets.bot(`blue_bot${lo}` as 'blue_bot'), MAX_AGENTS, skin);
    this.grunt = new BotMesh(assets.bot(`red_grunt${lo}` as 'red_grunt'), MAX_ENEMIES);
    this.brute = new BotMesh(assets.bot(`red_brute${lo}` as 'red_brute'), 96);
    this.turret = new BotMesh(assets.bot('turret'), 16);
    this.group.add(this.blue.mesh, this.grunt.mesh, this.brute.mesh, this.turret.mesh);

    if (quality.blobShadows) {
      const geo = new THREE.CircleGeometry(0.42, 10).rotateX(-Math.PI / 2);
      const mat = new THREE.MeshBasicMaterial({ color: 0x000000, transparent: true, opacity: 0.3, depthWrite: false });
      this.shadows = new THREE.InstancedMesh(geo, mat, MAX_AGENTS + MAX_ENEMIES);
      this.shadows.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
      this.shadows.frustumCulled = false;
      this.shadows.renderOrder = 1;
      this.group.add(this.shadows);
    } else {
      this.shadows = null;
    }

    const podGeo = new THREE.CapsuleGeometry(0.16, 0.42, 3, 8).rotateX(Math.PI / 2);
    this.pods = new THREE.InstancedMesh(podGeo, new THREE.MeshBasicMaterial({ color: 0x8fe9ff }), 48);
    this.bolts = new THREE.InstancedMesh(new THREE.SphereGeometry(0.2, 8, 6), new THREE.MeshBasicMaterial({ color: 0xff5a3c }), 24);
    for (const m of [this.pods, this.bolts]) {
      m.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
      m.frustumCulled = false;
      m.count = 0;
      this.group.add(m);
    }
  }

  private shadowAt(index: number, x: number, z: number, scale: number): void {
    const m = this.shadows!.instanceMatrix.array as Float32Array;
    const o = index * 16;
    m.fill(0, o, o + 16);
    m[o] = scale; m[o + 5] = 1; m[o + 10] = scale; m[o + 15] = 1;
    m[o + 12] = x; m[o + 13] = 0.02; m[o + 14] = -z;
  }

  update(sim: Simulation): void {
    const { crowd, enemies } = sim;
    const zMin = sim.cannon.z - VIEW_BEHIND;
    const zMax = sim.cannon.z + VIEW_AHEAD;
    let shadows = 0;

    this.blue.begin();
    for (let i = 0; i < crowd.cap; i++) {
      const s = crowd.state[i]!;
      if (s === AgentState.Dead) continue;
      const z = crowd.z[i]!;
      if (z < zMin || z > zMax) continue;
      const x = crowd.x[i]!;
      const t = crowd.t[i]!;
      const str = crowd.str[i]!;
      let scale = agentScale(str) * 1.3;
      let y = 0;
      let tilt = 0;
      let clip: number = Anim.Run;
      let speed = 15;
      if (s === AgentState.Run) {
        if (crowd.speed[i]! < 0.6) (clip = Anim.Idle), (speed = 4);
        // pop in when deployed
        if (t < 0.18) scale *= 0.4 + (t / 0.18) * 0.6;
      } else if (s === AgentState.Fight) {
        clip = Anim.Attack;
        speed = 17;
      } else if (s === AgentState.Cheer) {
        clip = Anim.Cheer;
        speed = 11;
      } else if (s === AgentState.Fall) {
        clip = Anim.Fall;
        y = -t * t * 16;
        tilt = t * 5;
      } else {
        clip = Anim.Die;
        y = Math.sin(Math.min(1, t / 0.6) * Math.PI) * 0.7;
        tilt = t * 4;
        scale *= Math.max(0, 1 - t / 0.65);
      }
      // merged agents (strength > 1) are bigger and brighter
      const boost = str > 1 ? 1.25 : 1;
      this.blue.push(x, y, -z, -1, 0, scale, tilt, crowd.phase[i]!, clip, 0, speed, boost, boost, boost);
      if (this.shadows && y === 0) this.shadowAt(shadows++, x, z, scale * 0.85);
    }
    this.blue.end();

    this.grunt.begin();
    this.brute.begin();
    this.turret.begin();
    for (let i = 0; i < enemies.cap; i++) {
      const s = enemies.state[i]!;
      if (s === EnemyState.Dead) continue;
      const z = enemies.z[i]!;
      if (z < zMin || z > zMax) continue;
      const kind = enemies.kind[i]!;
      const stats = ENEMY_STATS[kind]!;
      const x = enemies.x[i]!;
      const t = enemies.t[i]!;
      let scale = stats.scale * (kind === 3 ? 1 : 1.25);
      let y = 0;
      let zz = z;
      let tilt = 0;
      let clip: number = s === EnemyState.March ? Anim.Run : s === EnemyState.Fight ? Anim.Attack : Anim.Idle;
      let speed = s === EnemyState.March ? 9 / Math.sqrt(scale) : s === EnemyState.Fight ? 12 / Math.sqrt(scale) : 3;
      if (s === EnemyState.Dying) {
        // knocked back and shrinking
        clip = Anim.Die;
        speed = 14;
        const k = t / 0.6;
        zz = z + k * 1.6;
        y = Math.sin(k * Math.PI) * 0.8 * scale;
        tilt = -k * 2.2;
        scale *= 1 - k * k;
      }
      const flash = enemies.flash[i]!;
      if (kind === 3) {
        this.turret.push(x, y, -zz, 1, 0, scale, tilt, 0, Anim.Static, flash, 0);
      } else if (kind === 0) {
        this.grunt.push(x, y, -zz, 1, 0, scale, tilt, enemies.phase[i]!, clip, flash, speed);
      } else {
        const dark = kind === 2 ? 0.72 : 1;
        this.brute.push(x, y, -zz, 1, 0, scale, tilt, enemies.phase[i]!, clip, flash, speed, 1, dark, dark);
      }
      if (this.shadows && s !== EnemyState.Dying) this.shadowAt(shadows++, x, z, scale);
    }
    this.grunt.end();
    this.brute.end();
    this.turret.end();
    if (this.shadows) {
      this.shadows.count = shadows;
      this.shadows.instanceMatrix.needsUpdate = true;
    }

    const d = this.dummy;
    let n = 0;
    for (let i = 0; i < sim.pods.cap; i++) {
      if (!sim.pods.live[i]) continue;
      const travelled = (sim.pods.z[i]! - sim.pods.startZ[i]!) / 6.5;
      d.position.set(sim.pods.x[i]!, 1.0 + Math.sin(Math.min(1, travelled) * Math.PI) * 0.9, -sim.pods.z[i]!);
      d.rotation.set((0.5 - travelled) * 0.6, 0, 0);
      d.scale.setScalar(1);
      d.updateMatrix();
      this.pods.setMatrixAt(n++, d.matrix);
    }
    this.pods.count = n;
    this.pods.instanceMatrix.needsUpdate = true;

    n = 0;
    d.rotation.set(0, 0, 0);
    for (let i = 0; i < enemies.boltCap; i++) {
      if (!enemies.boltLive[i]) continue;
      d.position.set(enemies.boltX[i]!, 1.2 + Math.sin(enemies.boltT[i]! * Math.PI) * 1.6, -enemies.boltZ[i]!);
      d.updateMatrix();
      this.bolts.setMatrixAt(n++, d.matrix);
    }
    this.bolts.count = n;
    this.bolts.instanceMatrix.needsUpdate = true;
    this.drawn = this.blue.count + this.grunt.count + this.brute.count + this.turret.count;
  }

  dispose(): void {
    for (const b of [this.blue, this.grunt, this.brute, this.turret]) b.dispose();
    for (const m of [this.pods, this.bolts, this.shadows]) {
      m?.geometry.dispose();
      (m?.material as THREE.Material | undefined)?.dispose();
    }
  }
}
