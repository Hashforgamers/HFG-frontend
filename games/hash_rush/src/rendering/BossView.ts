import * as THREE from 'three';
import type { AssetManager } from '../core/AssetManager';
import { BossState, DEATH_TIME, INTRO_TIME, type BossSystem } from '../gameplay/BossSystem';

const ease = (t: number) => t * t * (3 - 2 * t);
const sat = (t: number) => (t < 0 ? 0 : t > 1 ? 1 : t);

/**
 * Bosses are rigid-part models animated procedurally: each named part
 * (torso, head, armL, armR, legL, legR, ring, core) is rotated about its
 * joint by a small state machine driven by the simulation.
 */
export class BossView {
  readonly group = new THREE.Group();
  private readonly model: THREE.Group;
  private readonly parts: Record<string, THREE.Object3D | undefined> = {};
  private readonly mats: { mat: THREE.MeshStandardMaterial; base: THREE.Color; glows: boolean; intensity: number }[] = [];
  private readonly shield: THREE.Mesh;
  /** Height of the model's head, for effects and the camera. */
  readonly height = 7;

  constructor(private readonly boss: BossSystem, assets: AssetManager) {
    this.model = assets.model(`boss_${boss.kind}` as 'boss_titan');
    this.model.traverse((o) => {
      if (o.name) this.parts[o.name] = this.parts[o.name] ?? o;
      const mesh = o as THREE.Mesh;
      if (!mesh.isMesh) return;
      const mat = mesh.material as THREE.MeshStandardMaterial;
      if (this.mats.some((m) => m.mat === mat)) return;
      const glows = mat.emissive.r + mat.emissive.g + mat.emissive.b > 0.01;
      // GLTF emission strengths are tuned for a bloom pipeline; tame them for ours
      if (glows) mat.emissiveIntensity = 1.6;
      this.mats.push({ mat, base: mat.emissive.clone(), glows, intensity: mat.emissiveIntensity });
    });
    this.group.add(this.model);
    this.shield = new THREE.Mesh(
      new THREE.SphereGeometry(boss.stats.radius + 2.4, 20, 14),
      new THREE.MeshBasicMaterial({ color: 0xb06bff, transparent: true, opacity: 0.25, blending: THREE.AdditiveBlending, depthWrite: false, wireframe: false }),
    );
    this.shield.position.y = 4;
    this.shield.visible = false;
    this.group.add(this.shield);
    this.group.visible = false;
  }

  update(time: number): void {
    const b = this.boss;
    const { torso, head, armL, armR, legL, legR, ring, core } = this.parts;
    const g = this.group;
    g.visible = b.state !== BossState.Dormant && b.state !== BossState.Dead;
    if (!g.visible) return;
    const floats = b.kind === 'void';
    let y = floats ? 1.1 + Math.sin(time * 1.6) * 0.3 : 0;
    let scale = 1;
    let pitch = 0;
    let armLx = Math.sin(time * 1.3) * 0.08;
    let armRx = -Math.sin(time * 1.3) * 0.08;
    let armSpread = 0;
    let headX = Math.sin(time * 0.9) * 0.05;
    let torsoX = Math.sin(time * 1.3) * 0.025;
    let legSwing = 0;

    if (b.state === BossState.Intro) {
      const k = sat(b.t / INTRO_TIME);
      if (b.kind === 'titan') {
        // drops out of the sky, lands, then flexes
        const fall = sat(b.t / 0.8);
        y = (1 - fall * fall) * 34;
        const land = sat((b.t - 0.8) / 0.4);
        scale = 1 - Math.sin(land * Math.PI) * 0.1;
        armSpread = ease(sat((b.t - 1.3) / 0.6)) * 0.9 * (1 - sat((b.t - 2.2) / 0.4));
        headX = -armSpread * 0.4;
      } else if (b.kind === 'inferno') {
        // climbs up out of the pit and roars
        y = -9 * (1 - ease(sat(b.t / 1.3)));
        const roar = Math.sin(sat((b.t - 1.4) / 1.0) * Math.PI);
        headX = -roar * 0.6;
        armLx = armRx = -roar * 0.8;
      } else {
        // descends, unfolding
        y += (1 - ease(k)) * 16;
        scale = 0.3 + 0.7 * ease(sat(b.t / 1.6));
        armSpread = (1 - ease(k)) * 1.2;
      }
    } else if (b.state === BossState.Fight) {
      const t = b.attackT;
      if (t < 1.7 && b.attack) {
        const wind = ease(sat(t / 1.0));
        const strike = sat((t - 1.1) / 0.18);
        const recover = sat((t - 1.3) / 0.4);
        const swing = -2.5 * wind * (1 - strike) + 0.5 * strike * (1 - recover);
        switch (b.attack) {
          case 'slam': case 'stomp':
            armLx = armRx = swing;
            torsoX = -0.18 * wind + 0.34 * strike * (1 - recover);
            if (b.attack === 'stomp') legSwing = -0.7 * wind * (1 - strike);
            break;
          case 'boulder': case 'fireball': case 'orbs':
            armRx = swing;
            torsoX = -0.1 * wind + 0.2 * strike * (1 - recover);
            break;
          case 'flame': case 'beam':
            headX = 0.45 * wind * (1 - recover);
            armLx = armRx = 0.5 * wind * (1 - recover);
            torsoX = 0.2 * wind * (1 - recover);
            break;
          case 'summon': case 'blink':
            armSpread = Math.sin(sat(t / 1.4) * Math.PI) * 1.1;
            headX = -0.3 * Math.sin(sat(t / 1.4) * Math.PI);
            break;
        }
      }
      if (b.enraged) {
        g.position.x += Math.sin(time * 50) * 0.03;
      }
    } else if (b.state === BossState.Dying) {
      const k = sat(b.t / DEATH_TIME);
      pitch = -ease(k) * 1.25;
      y += -k * k * 3 + Math.sin(time * 70) * 0.08 * (1 - k);
      scale = 1 - ease(sat((k - 0.7) / 0.3)) * 0.6;
      armSpread = k * 1.2;
      headX = -k * 0.6;
    }

    g.position.set(b.x + (b.state === BossState.Dying ? Math.sin(time * 61) * 0.12 : 0), y, -b.z);
    g.scale.setScalar(scale);
    this.model.rotation.x = pitch;
    if (torso) torso.rotation.x = torsoX;
    if (head) head.rotation.x = headX;
    if (armL) armL.rotation.set(armLx, 0, -armSpread);
    if (armR) armR.rotation.set(armRx, 0, armSpread);
    if (legL) legL.rotation.x = legSwing;
    if (legR) legR.rotation.x = 0;
    if (ring) ring.rotation.y = time * 1.4;
    if (core) core.scale.setScalar(1 + Math.sin(time * 6) * 0.15);

    // hit flash, plus a heat pulse on the glowing parts when enraged
    const flash = b.flash;
    const pulse = b.enraged ? 0.6 + Math.sin(time * 12) * 0.4 : 0;
    for (const m of this.mats) {
      if (m.glows) {
        m.mat.emissiveIntensity = m.intensity * (1 + pulse) + flash * 2;
      } else {
        m.mat.emissive.setRGB(flash * 0.3, flash * 0.26, flash * 0.22);
      }
    }
    this.shield.visible = b.shield > 0;
    if (this.shield.visible) {
      const mat = this.shield.material as THREE.MeshBasicMaterial;
      mat.opacity = 0.14 + 0.2 * (b.shield / Math.max(1, b.shieldMax)) + Math.sin(time * 9) * 0.04;
      this.shield.rotation.y = time;
    }
  }

  dispose(): void {
    for (const m of this.mats) m.mat.dispose();
    this.shield.geometry.dispose();
    (this.shield.material as THREE.Material).dispose();
    this.group.removeFromParent();
  }
}
