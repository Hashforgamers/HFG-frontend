import * as THREE from 'three';
import { BossState } from '../gameplay/BossSystem';
import type { Simulation } from '../gameplay/Simulation';

/**
 * Elevated third-person camera. It follows the cannon, pulls back as the army
 * grows or a battle starts, reframes for the boss, and never drops low enough
 * to clip the deck or the crowd.
 */
export class CameraController {
  readonly camera = new THREE.PerspectiveCamera(58, 9 / 16, 0.5, 420);
  private readonly pos = new THREE.Vector3(0, 12, 12);
  private readonly look = new THREE.Vector3(0, 0, -10);
  private readonly wantPos = new THREE.Vector3();
  private readonly wantLook = new THREE.Vector3();
  private shakeAmount = 0;
  private snap = true;
  /** Menu shots: look this far below the subject, so it sits higher on screen (skin shop sheet). */
  lookDrop = 0;

  setAspect(aspect: number): void {
    this.camera.aspect = aspect;
    // keep the same horizontal coverage of the track on tall and wide viewports
    const hFov = 36;
    const v = (2 * Math.atan(Math.tan((hFov * Math.PI) / 360) / aspect) * 180) / Math.PI;
    this.camera.fov = Math.max(40, Math.min(66, v));
    this.camera.updateProjectionMatrix();
  }

  shake(amount: number): void {
    this.shakeAmount = Math.min(1.2, Math.max(this.shakeAmount, amount));
  }

  /** Jump to the target on the next update (level start). */
  reset(): void {
    this.snap = true;
    this.shakeAmount = 0;
  }

  update(dt: number, sim: Simulation, time: number, attract: boolean): void {
    const c = sim.cannon;
    const boss = sim.boss;
    const army = Math.min(1, Math.sqrt(sim.crowd.count) / 22);
    const fighting = sim.enemies.blockerZ < Infinity ? 1 : 0;
    let height = 8.6 + army * 3.6 + fighting * 1;
    let back = 9.4 + army * 2.4 + fighting * 0.8;
    let ahead = 7.5 + army * 3.5;
    let px = c.x * 0.32;
    let lx = c.x * 0.2;

    if (boss.state === BossState.Intro) {
      // look up at the boss while it arrives
      const k = Math.min(1, boss.t / 0.6);
      height = 9.5;
      back = 9;
      ahead = THREE.MathUtils.lerp(ahead, boss.z - c.z, k);
      this.wantLook.set(lx * 0.3, 4.5 * k, -(c.z + ahead));
    } else if (boss.state === BossState.Fight || boss.state === BossState.Dying) {
      // frame cannon and boss together
      height = 13.5;
      back = 9.5;
      ahead = (boss.z - c.z) * 0.62;
      this.wantLook.set(lx * 0.4, 1.5, -(c.z + ahead));
    } else {
      this.wantLook.set(lx, 0.5, -(c.z + ahead));
    }
    if (attract) {
      // main menu: slow orbit around the cannon
      // main menu: hero shot from ahead of the cannon, drifting side to side
      const a = Math.sin(time * 0.22) * 0.7;
      this.wantPos.set(Math.sin(a) * 7, 2.7 + Math.sin(time * 0.4) * 0.3, -(c.z + 3) - Math.cos(a) * 7.5);
      this.wantLook.set(0, 2.3 - this.lookDrop, -(c.z + 1.8));
    } else {
      this.wantPos.set(px, height, -c.z + back);
    }

    const k = this.snap ? 1 : 1 - Math.exp(-dt * 4.5);
    this.snap = false;
    this.pos.lerp(this.wantPos, k);
    this.look.lerp(this.wantLook, k);
    this.camera.position.copy(this.pos);
    if (this.shakeAmount > 0.002) {
      const s = this.shakeAmount * 0.45;
      this.camera.position.x += (Math.random() - 0.5) * s;
      this.camera.position.y += (Math.random() - 0.5) * s;
      this.shakeAmount *= Math.exp(-dt * 7);
    }
    if (this.camera.position.y < 3) this.camera.position.y = 3;
    this.camera.lookAt(this.look);
  }
}
