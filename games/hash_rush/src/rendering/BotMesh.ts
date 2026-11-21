import * as THREE from 'three';
import type { BotModel } from '../core/AssetManager';
import { recolor, type SkinDef } from '../gameplay/Skins';

/** Animation clips of the crowd shader (per-instance `state`). */
export const Anim = { Idle: 0, Run: 1, Attack: 2, Fall: 3, Die: 4, Cheer: 5, Static: 6 } as const;

/** Shared clock for every crowd material. */
export const crowdTime = { value: 0 };

const VERT_HEAD = /* glsl */ `
attribute float aPart;
attribute float aEmit;
attribute vec4 iAnim; // phase, clip, flash, speed
uniform vec3 uPivot[6];
uniform float uTime;
varying float vEmit;
varying float vFlash;
vec3 hrRot(vec3 p, float a) {
  float c = cos(a), s = sin(a);
  return vec3(p.x, p.y * c - p.z * s, p.y * s + p.z * c);
}
// Limb swing angle (about the part's joint, X axis) and whole-body lift for this vertex.
float hrAngle(out float lift) {
  float clip = iAnim.y;
  float ph = iAnim.x + uTime * iAnim.w;
  bool arm = aPart > 0.5 && aPart < 2.5;
  bool leg = aPart > 2.5 && aPart < 4.5;
  float side = (abs(aPart - 1.0) < 0.5 || abs(aPart - 4.0) < 0.5) ? 1.0 : -1.0;
  lift = 0.0;
  if (clip < 0.5) { // idle: breathe
    lift = sin(ph) * 0.012;
    return arm ? sin(ph) * 0.07 * side : 0.0;
  }
  if (clip < 1.5) { // run
    lift = abs(sin(ph)) * 0.07;
    if (arm) return sin(ph) * 0.85 * side;
    if (leg) return -sin(ph) * 0.95 * side;
    return 0.0;
  }
  if (clip < 2.5) { // attack: alternate punches
    lift = abs(sin(ph * 0.5)) * 0.04;
    if (arm) return -1.45 + sin(ph + (side > 0.0 ? 0.0 : 3.1416)) * 0.85;
    if (leg) return side * 0.3;
    return 0.0;
  }
  if (clip < 4.5) { // fall / die: flail
    return (arm || leg) ? sin(ph * 1.7 + aPart * 2.0) * 1.4 : 0.0;
  }
  if (clip < 5.5) { // cheer: arms up, hop
    lift = abs(sin(ph * 0.5)) * 0.32;
    return arm ? -2.75 + sin(ph) * 0.3 * side : 0.0;
  }
  return 0.0;
}
`;

function makeMaterial(pivots: THREE.Vector3[]): THREE.MeshLambertMaterial {
  const material = new THREE.MeshLambertMaterial({ vertexColors: true });
  material.onBeforeCompile = (shader) => {
    shader.uniforms.uPivot = { value: pivots };
    shader.uniforms.uTime = crowdTime;
    shader.vertexShader = shader.vertexShader
      .replace('#include <common>', '#include <common>\n' + VERT_HEAD)
      .replace(
        '#include <beginnormal_vertex>',
        '#include <beginnormal_vertex>\nfloat hrLift;\nfloat hrA = hrAngle(hrLift);\nobjectNormal = hrRot(objectNormal, hrA);',
      )
      .replace(
        '#include <begin_vertex>',
        `#include <begin_vertex>
        vec3 hrP = uPivot[int(aPart + 0.5)];
        transformed = hrRot(transformed - hrP, hrA) + hrP;
        transformed.y += hrLift;
        vEmit = aEmit;
        vFlash = iAnim.z;`,
      );
    shader.fragmentShader = shader.fragmentShader
      .replace('#include <common>', '#include <common>\nvarying float vEmit;\nvarying float vFlash;')
      .replace(
        '#include <emissivemap_fragment>',
        `#include <emissivemap_fragment>
        float hrRim = pow(1.0 - clamp(dot(normalize(vViewPosition), normal), 0.0, 1.0), 2.5);
        totalEmissiveRadiance += diffuseColor.rgb * (vEmit * 2.6 + hrRim * 0.75) + vec3(vFlash * 0.55);
        diffuseColor.rgb = mix(diffuseColor.rgb, vec3(1.0), vFlash * 0.7);`,
      );
  };
  material.customProgramCacheKey = () => 'hash-rush-bot';
  return material;
}

/**
 * One draw call for a whole crowd of one character type. Limbs are animated
 * in the vertex shader from a per-instance clip + phase, so the CPU only
 * writes a matrix and four floats per visible unit each frame.
 */
export class BotMesh {
  readonly mesh: THREE.InstancedMesh;
  private readonly matrices: Float32Array;
  private readonly anim: Float32Array;
  private readonly colors: Float32Array;
  private readonly animAttr: THREE.InstancedBufferAttribute;
  private n = 0;

  constructor(model: BotModel, readonly capacity: number, skin?: SkinDef) {
    const geometry = model.geometry.clone();
    if (skin) {
      const color = geometry.attributes.color as THREE.BufferAttribute;
      const emit = geometry.attributes.aEmit as THREE.BufferAttribute;
      const accent = new THREE.Color(skin.accent);
      const c = { r: 0, g: 0, b: 0 };
      for (let i = 0; i < color.count; i++) {
        if (emit.getX(i) > 0.5) {
          color.setXYZ(i, accent.r, accent.g, accent.b);
        } else {
          c.r = color.getX(i); c.g = color.getY(i); c.b = color.getZ(i);
          recolor(c, skin);
          color.setXYZ(i, c.r, c.g, c.b);
        }
      }
    }
    this.anim = new Float32Array(capacity * 4);
    this.animAttr = new THREE.InstancedBufferAttribute(this.anim, 4);
    this.animAttr.setUsage(THREE.DynamicDrawUsage);
    geometry.setAttribute('iAnim', this.animAttr);
    this.mesh = new THREE.InstancedMesh(geometry, makeMaterial(model.pivots), capacity);
    this.mesh.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
    this.mesh.frustumCulled = false; // instances are culled by hand in the views
    this.matrices = this.mesh.instanceMatrix.array as Float32Array;
    this.colors = new Float32Array(capacity * 3).fill(1);
    this.mesh.instanceColor = new THREE.InstancedBufferAttribute(this.colors, 3);
    this.mesh.instanceColor.setUsage(THREE.DynamicDrawUsage);
    this.mesh.count = 0;
  }

  begin(): void {
    this.n = 0;
  }

  /** `cosY`/`sinY`: heading; `tilt`: pitch about the feet, radians. */
  push(
    x: number, y: number, z: number, cosY: number, sinY: number, scale: number, tilt: number,
    phase: number, clip: number, flash: number, speed: number, r = 1, g = 1, b = 1,
  ): void {
    if (this.n >= this.capacity) return;
    const i = this.n++;
    const m = this.matrices;
    const o = i * 16;
    const ct = tilt === 0 ? 1 : Math.cos(tilt);
    const st = tilt === 0 ? 0 : Math.sin(tilt);
    m[o] = cosY * scale; m[o + 1] = 0; m[o + 2] = -sinY * scale; m[o + 3] = 0;
    m[o + 4] = sinY * st * scale; m[o + 5] = ct * scale; m[o + 6] = cosY * st * scale; m[o + 7] = 0;
    m[o + 8] = sinY * ct * scale; m[o + 9] = -st * scale; m[o + 10] = cosY * ct * scale; m[o + 11] = 0;
    m[o + 12] = x; m[o + 13] = y; m[o + 14] = z; m[o + 15] = 1;
    const a = i * 4;
    this.anim[a] = phase; this.anim[a + 1] = clip; this.anim[a + 2] = flash; this.anim[a + 3] = speed;
    const c = i * 3;
    this.colors[c] = r; this.colors[c + 1] = g; this.colors[c + 2] = b;
  }

  end(): void {
    this.mesh.count = this.n;
    this.mesh.instanceMatrix.needsUpdate = true;
    this.animAttr.needsUpdate = true;
    this.mesh.instanceColor!.needsUpdate = true;
  }

  get count(): number {
    return this.n;
  }

  dispose(): void {
    this.mesh.geometry.dispose();
    (this.mesh.material as THREE.Material).dispose();
  }
}
