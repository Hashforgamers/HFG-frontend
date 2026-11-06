import * as THREE from 'three';
import type { AssetManager } from '../core/AssetManager';
import type { Telegraph } from '../gameplay/BossSystem';
import type { ObstacleRuntime } from '../gameplay/ObstacleSystem';
import { TRACK_HALF } from '../gameplay/constants';

const DANGER = 0xff2d2d;
const WARN = 0xffc21f;

function hazardTexture(): THREE.CanvasTexture {
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = 64;
  const g = canvas.getContext('2d')!;
  g.fillStyle = '#16161c';
  g.fillRect(0, 0, 64, 64);
  g.fillStyle = '#ffc21f';
  for (let i = -64; i < 128; i += 32) {
    g.beginPath();
    g.moveTo(i, 64); g.lineTo(i + 16, 64); g.lineTo(i + 80, 0); g.lineTo(i + 64, 0);
    g.fill();
  }
  const tex = new THREE.CanvasTexture(canvas);
  tex.colorSpace = THREE.SRGBColorSpace;
  tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  return tex;
}

/** Ground decal that pulses from amber (warning) to red (lethal). */
function decal(w: number, d: number): THREE.Mesh {
  const mesh = new THREE.Mesh(
    new THREE.PlaneGeometry(w, d).rotateX(-Math.PI / 2),
    new THREE.MeshBasicMaterial({ color: WARN, transparent: true, opacity: 0.2, depthWrite: false }),
  );
  mesh.position.y = 0.03;
  mesh.renderOrder = 2;
  return mesh;
}

type Updater = (time: number) => void;

/** One small mesh group per trap. Each shows its warning state before it becomes lethal. */
export class ObstacleView {
  readonly group = new THREE.Group();
  private readonly updaters: Updater[] = [];
  private readonly hazard = hazardTexture();

  constructor(list: readonly ObstacleRuntime[], assets: AssetManager, trackColor: THREE.ColorRepresentation) {
    const steel = new THREE.MeshLambertMaterial({ color: 0x4a4f5c, flatShading: true });
    const striped = new THREE.MeshLambertMaterial({ map: this.hazard });
    const glow = (color: number) => new THREE.MeshBasicMaterial({ color });
    for (const o of list) {
      const def = o.def;
      const g = new THREE.Group();
      this.group.add(g);
      switch (def.kind) {
        case 'movingWall': {
          const wall = new THREE.Mesh(new THREE.BoxGeometry(def.width, 2.4, 0.8), striped);
          wall.position.y = 1.2;
          const edge = new THREE.Mesh(new THREE.BoxGeometry(def.width + 0.1, 0.16, 0.9), glow(DANGER));
          edge.position.y = 2.46;
          const rail = new THREE.Mesh(new THREE.BoxGeometry(TRACK_HALF * 2, 0.08, 0.3), steel);
          rail.position.set(0, 0.04, 0);
          const lane = decal(def.width, 1.6);
          g.add(wall, edge, lane);
          this.group.add(rail);
          rail.position.z = -def.z;
          g.position.z = -def.z;
          this.updaters.push((time) => {
            g.position.x = o.x;
            (lane.material as THREE.MeshBasicMaterial).color.setHex(DANGER);
            (lane.material as THREE.MeshBasicMaterial).opacity = 0.25 + Math.sin(time * 8) * 0.1;
          });
          break;
        }
        case 'blade': {
          const hub = new THREE.Mesh(new THREE.CylinderGeometry(0.42, 0.5, 0.9, 10), steel);
          hub.position.y = 0.45;
          const spin = new THREE.Group();
          const arm = new THREE.Mesh(new THREE.BoxGeometry(def.radius * 2, 0.12, 0.5), new THREE.MeshLambertMaterial({ color: 0xcfd6e4 }));
          const edge = new THREE.Mesh(new THREE.BoxGeometry(def.radius * 2, 0.05, 0.62), glow(DANGER));
          spin.add(arm, edge);
          spin.position.y = 0.7;
          const ring = new THREE.Mesh(
            new THREE.RingGeometry(def.radius - 0.12, def.radius, 40).rotateX(-Math.PI / 2),
            new THREE.MeshBasicMaterial({ color: DANGER, transparent: true, opacity: 0.6, depthWrite: false }),
          );
          ring.position.y = 0.03;
          const disc = new THREE.Mesh(
            new THREE.CircleGeometry(def.radius, 32).rotateX(-Math.PI / 2),
            new THREE.MeshBasicMaterial({ color: DANGER, transparent: true, opacity: 0.1, depthWrite: false }),
          );
          disc.position.y = 0.025;
          g.add(hub, spin, ring, disc);
          g.position.set(def.x, 0, -def.z);
          // sim angle is measured in the x/z plane; rendered z is flipped, hence the sign
          this.updaters.push(() => (spin.rotation.y = o.angle));
          break;
        }
        case 'crusher': {
          const postGeo = new THREE.BoxGeometry(0.4, 5, 0.4);
          for (const sx of [-1, 1]) {
            const post = new THREE.Mesh(postGeo, steel);
            post.position.set(sx * (def.width / 2 + 0.25), 2.5, 0);
            g.add(post);
          }
          const beam = new THREE.Mesh(new THREE.BoxGeometry(def.width + 0.9, 0.5, 0.8), steel);
          beam.position.y = 5.1;
          const head = new THREE.Mesh(new THREE.BoxGeometry(def.width, 1.6, def.depth), striped);
          const rod = new THREE.Mesh(new THREE.BoxGeometry(0.5, 4, 0.5), steel);
          const pad = decal(def.width, def.depth);
          g.add(beam, head, rod, pad);
          g.position.set(def.x, 0, -def.z);
          const padMat = pad.material as THREE.MeshBasicMaterial;
          this.updaters.push((time) => {
            head.position.y = 0.8 + o.y * 2.6;
            rod.position.y = head.position.y + 2.6;
            padMat.color.setHex(o.danger === 2 ? DANGER : WARN);
            padMat.opacity = o.danger === 0 ? 0.14 : o.danger === 1 ? 0.35 + Math.sin(time * 22) * 0.25 : 0.6;
          });
          break;
        }
        case 'laser': {
          const w = def.x1 - def.x0;
          const cx = (def.x0 + def.x1) / 2;
          const emitterGeo = new THREE.CylinderGeometry(0.22, 0.3, 1.5, 8);
          for (const x of [def.x0, def.x1]) {
            const emitter = new THREE.Mesh(emitterGeo, steel);
            emitter.position.set(x - cx, 0.75, 0);
            const cap = new THREE.Mesh(new THREE.SphereGeometry(0.2, 8, 6), glow(DANGER));
            cap.position.set(x - cx, 1.0, 0);
            g.add(emitter, cap);
          }
          const beamMat = new THREE.MeshBasicMaterial({ color: DANGER, transparent: true, blending: THREE.AdditiveBlending, depthWrite: false });
          const beam = new THREE.Mesh(new THREE.BoxGeometry(w, 0.16, 0.16), beamMat);
          beam.position.y = 0.9;
          const halo = new THREE.Mesh(new THREE.BoxGeometry(w, 0.5, 0.5), beamMat.clone());
          halo.position.y = 0.9;
          const line = decal(w, 0.5);
          g.add(beam, halo, line);
          g.position.set(cx, 0, -def.z);
          const lineMat = line.material as THREE.MeshBasicMaterial;
          this.updaters.push((time) => {
            const on = o.danger === 2;
            beam.visible = o.danger > 0;
            beamMat.opacity = on ? 1 : (Math.sin(time * 30) > 0 ? 0.35 : 0.08);
            beam.scale.y = beam.scale.z = on ? 1 + Math.sin(time * 40) * 0.2 : 0.3;
            halo.visible = on;
            (halo.material as THREE.MeshBasicMaterial).opacity = 0.22;
            lineMat.color.setHex(on ? DANGER : WARN);
            lineMat.opacity = on ? 0.5 : o.danger === 1 ? 0.4 : 0.12;
          });
          break;
        }
        case 'bridge': {
          // the floor is cut by the Environment; here: guide arrows and edge beacons
          const w = def.x1 - def.x0;
          const cx = (def.x0 + def.x1) / 2;
          const guide = decal(w - 0.6, 1.2);
          (guide.material as THREE.MeshBasicMaterial).color.setHex(0x3fd5ff);
          guide.position.set(cx, 0.03, -(def.z0 - 2.5));
          g.add(guide);
          const beaconGeo = new THREE.BoxGeometry(0.2, 1.1, 0.2);
          for (const x of [def.x0, def.x1]) for (const z of [def.z0, def.z1]) {
            const beacon = new THREE.Mesh(beaconGeo, glow(WARN));
            beacon.position.set(x, 0.55, -z);
            g.add(beacon);
          }
          const guideMat = guide.material as THREE.MeshBasicMaterial;
          this.updaters.push((time) => (guideMat.opacity = 0.3 + Math.sin(time * 5) * 0.15));
          break;
        }
        case 'fallingPlatform': {
          const w = def.x1 - def.x0;
          const d = def.z1 - def.z0;
          const slabMat = new THREE.MeshLambertMaterial({ color: new THREE.Color(trackColor).multiplyScalar(0.75) });
          const slab = new THREE.Mesh(new THREE.BoxGeometry(w - 0.08, 0.5, d - 0.08), slabMat);
          const mark = new THREE.Mesh(
            new THREE.PlaneGeometry(w - 0.5, d - 0.5).rotateX(-Math.PI / 2),
            new THREE.MeshBasicMaterial({ map: this.hazard, transparent: true, opacity: 0.55, depthWrite: false }),
          );
          mark.position.y = 0.27;
          slab.add(mark);
          g.add(slab);
          const home = new THREE.Vector3((def.x0 + def.x1) / 2, -0.25, -(def.z0 + def.z1) / 2);
          let fallen = 0;
          this.updaters.push((time) => {
            if (o.stage === 2) {
              fallen += 0.016;
              slab.position.set(home.x, home.y - fallen * fallen * 18, home.z);
              slab.rotation.z = fallen * 0.8;
              slab.visible = fallen < 2;
            } else {
              const shake = o.stage === 1 ? 0.07 : 0;
              slab.position.set(home.x + Math.sin(time * 60) * shake, home.y + Math.sin(time * 47) * shake, home.z);
              slabMat.emissive.setHex(o.stage === 1 ? 0x661500 : 0);
            }
          });
          break;
        }
        case 'barrel': {
          const model = assets.model('barrel');
          model.scale.setScalar(1.15);
          const ring = new THREE.Mesh(
            new THREE.RingGeometry(0.75, 0.9, 24).rotateX(-Math.PI / 2),
            new THREE.MeshBasicMaterial({ color: 0xff7a1a, transparent: true, opacity: 0.7, depthWrite: false }),
          );
          ring.position.y = 0.03;
          g.add(model, ring);
          g.position.set(def.x, 0, -def.z);
          this.updaters.push((time) => {
            g.visible = o.stage === 0;
            ring.scale.setScalar(1 + (Math.sin(time * 5) * 0.5 + 0.5) * 0.25);
          });
          break;
        }
      }
    }
  }

  update(time: number): void {
    for (const fn of this.updaters) fn(time);
  }

  dispose(): void {
    this.hazard.dispose();
    this.group.traverse((o) => {
      const mesh = o as THREE.Mesh;
      if (!mesh.isMesh) return;
      mesh.geometry.dispose();
      (mesh.material as THREE.Material).dispose();
    });
    this.group.removeFromParent();
  }
}

const TG_FRAG = /* glsl */ `
uniform float uT; uniform float uShape; uniform vec2 uSize;
varying vec2 vUv;
void main(){
  vec2 p = vUv * 2.0 - 1.0;
  float d = uShape < 0.5 ? length(p) : max(abs(p.x), abs(p.y));
  if (d > 1.0) discard;
  // the fill grows from the centre and reaches the rim exactly when the attack lands
  float fill = step(d, uT);
  float rim = smoothstep(0.86, 1.0, d);
  float blink = 0.75 + 0.25 * sin(uT * 40.0);
  float a = 0.16 + fill * 0.34 * blink + rim * 0.7;
  gl_FragColor = vec4(mix(vec3(1.0, 0.72, 0.1), vec3(1.0, 0.12, 0.08), uT), a);
  #include <colorspace_fragment>
}`;

/** Ground warnings for the boss's area attacks. */
export class TelegraphView {
  readonly group = new THREE.Group();
  private readonly meshes: THREE.Mesh[] = [];

  constructor(private readonly telegraphs: readonly Telegraph[]) {
    const geo = new THREE.PlaneGeometry(2, 2).rotateX(-Math.PI / 2);
    for (let i = 0; i < telegraphs.length; i++) {
      const mat = new THREE.ShaderMaterial({
        uniforms: { uT: { value: 0 }, uShape: { value: 0 }, uSize: { value: new THREE.Vector2() } },
        vertexShader: /* glsl */ `varying vec2 vUv; void main(){ vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`,
        fragmentShader: TG_FRAG,
        transparent: true,
        depthWrite: false,
      });
      const mesh = new THREE.Mesh(geo, mat);
      mesh.renderOrder = 2;
      mesh.visible = false;
      this.meshes.push(mesh);
      this.group.add(mesh);
    }
  }

  update(): void {
    for (let i = 0; i < this.telegraphs.length; i++) {
      const tg = this.telegraphs[i]!;
      const mesh = this.meshes[i]!;
      mesh.visible = tg.live;
      if (!tg.live) continue;
      mesh.position.set(tg.x, 0.04, -tg.z);
      mesh.scale.set(tg.hw, 1, tg.shape === 0 ? tg.hw : tg.hd);
      const u = (mesh.material as THREE.ShaderMaterial).uniforms;
      u.uT!.value = Math.min(1, tg.t / tg.delay);
      u.uShape!.value = tg.shape;
    }
  }

  dispose(): void {
    this.meshes[0]?.geometry.dispose();
    for (const m of this.meshes) (m.material as THREE.Material).dispose();
    this.group.removeFromParent();
  }
}
