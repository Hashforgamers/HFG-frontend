import * as THREE from 'three';
import type { AssetManager } from '../core/AssetManager';
import type { Cannon } from '../gameplay/Cannon';
import { recolor, type SkinDef } from '../gameplay/Skins';

/** The player's hover cannon: bobbing, banking into turns, recoiling, flashing when hit. */
export class CannonView {
  readonly group = new THREE.Group();
  private readonly model: THREE.Group;
  private readonly barrel: THREE.Object3D | undefined;
  private readonly barrelRest = new THREE.Vector3();
  private readonly flashMesh: THREE.Mesh;
  private readonly glowRing: THREE.Mesh;
  private readonly mats: THREE.MeshStandardMaterial[] = [];
  private readonly glowMats: THREE.MeshStandardMaterial[] = [];
  private lastX = 0;
  private bank = 0;

  constructor(private readonly cannon: Cannon, assets: AssetManager, skin: SkinDef) {
    this.model = assets.model('cannon');
    this.model.rotation.y = Math.PI; // model faces +Z, the track runs towards -Z
    this.model.traverse((o) => {
      const mesh = o as THREE.Mesh;
      if (!mesh.isMesh) return;
      const mat = mesh.material as THREE.MeshStandardMaterial;
      if (this.mats.includes(mat) || this.glowMats.includes(mat)) return;
      if (mat.emissive.r + mat.emissive.g + mat.emissive.b > 0.01) {
        mat.emissiveIntensity = 1.8;
        // the engine exhausts stay orange; every other light takes the skin's accent
        if (mat.emissive.b > mat.emissive.r) {
          mat.emissive.setHex(skin.accent);
          mat.color.setHex(skin.accent);
        }
        this.glowMats.push(mat);
      } else {
        recolor(mat.color, skin);
        this.mats.push(mat);
      }
    });
    this.barrel = this.model.getObjectByName('barrel');
    if (this.barrel) this.barrelRest.copy(this.barrel.position);

    const flashTex = (() => {
      const c = document.createElement('canvas');
      c.width = c.height = 64;
      const g = c.getContext('2d')!;
      const grad = g.createRadialGradient(32, 32, 0, 32, 32, 32);
      grad.addColorStop(0, 'rgba(255,255,255,1)');
      grad.addColorStop(0.3, 'rgba(140,235,255,0.8)');
      grad.addColorStop(1, 'rgba(60,160,255,0)');
      g.fillStyle = grad;
      g.fillRect(0, 0, 64, 64);
      return new THREE.CanvasTexture(c);
    })();
    this.flashMesh = new THREE.Mesh(
      new THREE.PlaneGeometry(2.2, 2.2),
      new THREE.MeshBasicMaterial({ map: flashTex, transparent: true, blending: THREE.AdditiveBlending, depthWrite: false, opacity: 0 }),
    );
    this.flashMesh.position.set(0, 0.95, -1.9);
    this.glowRing = new THREE.Mesh(
      new THREE.RingGeometry(1.0, 1.25, 32).rotateX(-Math.PI / 2),
      new THREE.MeshBasicMaterial({ color: 0x4fe3ff, transparent: true, opacity: 0.5, blending: THREE.AdditiveBlending, depthWrite: false }),
    );
    this.glowRing.position.y = -0.2;
    this.group.add(this.model, this.flashMesh, this.glowRing);
  }

  update(time: number, dt: number, camera: THREE.Camera): void {
    const c = this.cannon;
    const vx = dt > 0 ? (c.x - this.lastX) / dt : 0;
    this.lastX = c.x;
    this.bank += (Math.max(-0.35, Math.min(0.35, -vx * 0.035)) - this.bank) * Math.min(1, dt * 10);
    this.group.position.set(c.x, 0.3 + Math.sin(time * 3) * 0.06, -c.z);
    this.model.rotation.z = -this.bank;
    if (this.barrel) this.barrel.position.copy(this.barrelRest).setZ(this.barrelRest.z - c.recoil * 0.3);
    const flash = this.flashMesh.material as THREE.MeshBasicMaterial;
    flash.opacity = c.recoil * c.recoil;
    this.flashMesh.scale.setScalar(0.6 + c.recoil * 0.8);
    this.flashMesh.quaternion.copy(camera.quaternion);
    const over = c.overdrive > 0;
    const ring = this.glowRing.material as THREE.MeshBasicMaterial;
    ring.color.setHex(over ? 0xffd23a : 0x4fe3ff);
    ring.opacity = (over ? 0.8 : 0.4) + Math.sin(time * (over ? 18 : 4)) * 0.15;
    this.glowRing.scale.setScalar(over ? 1.25 : 1);
    for (const mat of this.mats) mat.emissive.setRGB(c.hurt * 0.9, c.hurt * 0.1, c.hurt * 0.05);
  }

  dispose(): void {
    this.group.traverse((o) => {
      const mesh = o as THREE.Mesh;
      if (mesh.isMesh) (mesh.material as THREE.Material).dispose();
    });
    this.group.removeFromParent();
  }
}
