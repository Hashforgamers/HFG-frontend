import * as THREE from 'three';
import type { GateRuntime } from '../gameplay/GateSystem';
import { ADD_GATE_COOLDOWN } from '../gameplay/GateSystem';
import { gateLabel, type GateOp } from '../levels/LevelConfig';

/** Every gate value has its own colour so it reads at a glance. */
export function gateColor(op: GateOp): number {
  if (op.kind === 'sub') return 0xff3b3b;
  if (op.kind === 'div') return 0xc2132f;
  if (op.kind === 'add') return op.value >= 25 ? 0x19e0c8 : op.value >= 10 ? 0x2fe37a : op.value >= 5 ? 0x8fe83a : 0xc8e63a;
  return op.value >= 100 ? 0xffd21f : op.value >= 10 ? 0xff7a1a : op.value >= 5 ? 0xff3fa4 : op.value >= 3 ? 0xa45cff : 0x3d8bff;
}

const labelCache = new Map<string, THREE.CanvasTexture>();

function labelTexture(text: string): THREE.CanvasTexture {
  let tex = labelCache.get(text);
  if (tex) return tex;
  const canvas = document.createElement('canvas');
  canvas.width = 256;
  canvas.height = 128;
  const g = canvas.getContext('2d')!;
  g.font = `900 ${text.length > 3 ? 84 : 104}px system-ui, -apple-system, "Segoe UI", Roboto, sans-serif`;
  g.textAlign = 'center';
  g.textBaseline = 'middle';
  g.lineJoin = 'round';
  g.lineWidth = 14;
  g.strokeStyle = 'rgba(8,12,30,0.85)';
  g.strokeText(text, 128, 68);
  g.fillStyle = '#fff';
  g.fillText(text, 128, 68);
  tex = new THREE.CanvasTexture(canvas);
  tex.colorSpace = THREE.SRGBColorSpace;
  labelCache.set(text, tex);
  return tex;
}

const GLASS_VERT = /* glsl */ `varying vec2 vUv; void main(){ vUv = uv; gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0); }`;
const GLASS_FRAG = /* glsl */ `
uniform vec3 uColor; uniform float uTime; uniform float uFlash; uniform float uCharge;
varying vec2 vUv;
void main(){
  // glass: faint fill, rising scan lines, bright animated border
  vec2 e = min(vUv, 1.0 - vUv);
  float border = 1.0 - smoothstep(0.0, 0.07, min(e.x * 2.2, e.y));
  float run = 0.5 + 0.5 * sin((vUv.x + vUv.y) * 18.0 - uTime * 6.0);
  float scan = smoothstep(0.92, 1.0, fract(vUv.y * 7.0 - uTime * 0.8));
  float sheen = smoothstep(0.35, 0.0, abs(vUv.x - vUv.y * 0.6 - fract(uTime * 0.25) * 2.0 + 0.6));
  float a = 0.20 + border * (0.55 + 0.35 * run) + scan * 0.12 + sheen * 0.10 + uFlash * 0.5;
  // an additive gate that is recharging fills from the bottom
  float ready = step(vUv.y, uCharge);
  a *= mix(0.3, 1.0, ready);
  vec3 col = mix(uColor, vec3(1.0), border * 0.45 + uFlash * 0.6);
  gl_FragColor = vec4(col, a);
  #include <colorspace_fragment>
}`;

interface GateMesh {
  group: THREE.Group;
  uniforms: { uColor: { value: THREE.Color }; uTime: { value: number }; uFlash: { value: number }; uCharge: { value: number } };
  label: THREE.Mesh;
  frame: THREE.MeshBasicMaterial;
}

/** Multiplier gates: translucent glass pane, animated border, big label, coloured frame. */
export class GateView {
  readonly group = new THREE.Group();
  private readonly meshes: GateMesh[] = [];
  private readonly time = { value: 0 };

  constructor(private readonly gates: readonly GateRuntime[]) {
    const height = 3.4;
    for (const gate of gates) {
      const w = gate.def.width;
      const color = new THREE.Color(gateColor(gate.def.op));
      const group = new THREE.Group();
      const uniforms = { uColor: { value: color }, uTime: this.time, uFlash: { value: 0 }, uCharge: { value: 1 } };
      const glass = new THREE.Mesh(
        new THREE.PlaneGeometry(w, height),
        new THREE.ShaderMaterial({ uniforms, vertexShader: GLASS_VERT, fragmentShader: GLASS_FRAG, transparent: true, depthWrite: false, side: THREE.DoubleSide }),
      );
      glass.position.y = height / 2 + 0.1;
      glass.renderOrder = 3;
      const frameMat = new THREE.MeshBasicMaterial({ color });
      const post = new THREE.BoxGeometry(0.22, height + 0.5, 0.3);
      const left = new THREE.Mesh(post, frameMat);
      left.position.set(-w / 2, height / 2 + 0.1, 0);
      const right = new THREE.Mesh(post, frameMat);
      right.position.set(w / 2, height / 2 + 0.1, 0);
      const top = new THREE.Mesh(new THREE.BoxGeometry(w + 0.22, 0.26, 0.3), frameMat);
      top.position.y = height + 0.35;
      const foot = new THREE.Mesh(new THREE.BoxGeometry(w + 0.6, 0.08, 0.7), new THREE.MeshBasicMaterial({ color: color.clone().multiplyScalar(0.5) }));
      foot.position.y = 0.04;
      const label = new THREE.Mesh(
        new THREE.PlaneGeometry(Math.min(w * 0.82, 3.4), Math.min(w * 0.82, 3.4) / 2),
        new THREE.MeshBasicMaterial({ map: labelTexture(gateLabel(gate.def.op)), transparent: true, depthWrite: false }),
      );
      label.position.set(0, height / 2 + 0.25, 0.06);
      label.renderOrder = 4;
      group.add(glass, left, right, top, foot, label);
      group.position.set(gate.x, 0, -gate.def.z);
      this.group.add(group);
      this.meshes.push({ group, uniforms, label, frame: frameMat });
    }
  }

  update(time: number, cannonZ: number): void {
    this.time.value = time;
    for (let i = 0; i < this.gates.length; i++) {
      const gate = this.gates[i]!;
      const m = this.meshes[i]!;
      const dz = gate.def.z - cannonZ;
      // gates behind the cannon are spent; far ones are culled
      m.group.visible = dz > -2 && dz < 95;
      if (!m.group.visible) continue;
      m.group.position.x = gate.x;
      m.uniforms.uFlash.value = gate.flash;
      const kind = gate.def.op.kind;
      const charge = kind === 'add' || kind === 'sub' ? 1 - gate.cooldown / ADD_GATE_COOLDOWN : 1;
      m.uniforms.uCharge.value = charge >= 1 ? 2 : charge;
      (m.label.material as THREE.MeshBasicMaterial).opacity = charge >= 1 ? 1 : 0.4;
      const pulse = 1 + gate.flash * 0.12;
      m.group.scale.set(pulse, pulse, 1);
    }
  }

  dispose(): void {
    this.group.traverse((o) => {
      const mesh = o as THREE.Mesh;
      if (!mesh.isMesh) return;
      mesh.geometry.dispose();
      (mesh.material as THREE.Material).dispose();
    });
    this.group.removeFromParent();
  }
}
