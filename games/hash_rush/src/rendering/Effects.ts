import * as THREE from 'three';

class Particles {
  readonly points: THREE.Points;
  private readonly pos: Float32Array;
  private readonly col: Float32Array;
  private readonly size: Float32Array;
  private readonly alpha: Float32Array;
  private readonly vel: Float32Array;
  private readonly life: Float32Array;
  private readonly maxLife: Float32Array;
  private readonly grav: Float32Array;
  private cursor = 0;
  active = 0;

  constructor(readonly cap: number, additive: boolean) {
    this.pos = new Float32Array(cap * 3);
    this.col = new Float32Array(cap * 3);
    this.size = new Float32Array(cap);
    this.alpha = new Float32Array(cap);
    this.vel = new Float32Array(cap * 3);
    this.life = new Float32Array(cap);
    this.maxLife = new Float32Array(cap);
    this.grav = new Float32Array(cap);
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.BufferAttribute(this.pos, 3).setUsage(THREE.DynamicDrawUsage));
    geo.setAttribute('aColor', new THREE.BufferAttribute(this.col, 3).setUsage(THREE.DynamicDrawUsage));
    geo.setAttribute('aSize', new THREE.BufferAttribute(this.size, 1).setUsage(THREE.DynamicDrawUsage));
    geo.setAttribute('aAlpha', new THREE.BufferAttribute(this.alpha, 1).setUsage(THREE.DynamicDrawUsage));
    const mat = new THREE.ShaderMaterial({
      transparent: true,
      depthWrite: false,
      blending: additive ? THREE.AdditiveBlending : THREE.NormalBlending,
      uniforms: { uSoft: { value: additive ? 1 : 0 } },
      vertexShader: /* glsl */ `attribute vec3 aColor; attribute float aSize; attribute float aAlpha; varying vec3 vC; varying float vA;
        void main(){ vC = aColor; vA = aAlpha; vec4 mv = modelViewMatrix * vec4(position, 1.0);
          gl_Position = projectionMatrix * mv; gl_PointSize = aAlpha > 0.0 ? aSize * (260.0 / -mv.z) : 0.0; }`,
      fragmentShader: /* glsl */ `uniform float uSoft; varying vec3 vC; varying float vA;
        void main(){ float d = length(gl_PointCoord - 0.5);
          float a = uSoft > 0.5 ? smoothstep(0.5, 0.0, d) : 1.0;
          if (a * vA < 0.01) discard;
          gl_FragColor = vec4(vC, a * vA);
          #include <colorspace_fragment>
        }`,
    });
    this.points = new THREE.Points(geo, mat);
    this.points.frustumCulled = false;
    this.points.renderOrder = 5;
  }

  emit(x: number, y: number, z: number, vx: number, vy: number, vz: number, life: number, size: number, color: THREE.Color, gravity: number): void {
    const i = this.cursor;
    this.cursor = (i + 1) % this.cap;
    this.pos[i * 3] = x; this.pos[i * 3 + 1] = y; this.pos[i * 3 + 2] = z;
    this.vel[i * 3] = vx; this.vel[i * 3 + 1] = vy; this.vel[i * 3 + 2] = vz;
    this.col[i * 3] = color.r; this.col[i * 3 + 1] = color.g; this.col[i * 3 + 2] = color.b;
    this.life[i] = this.maxLife[i] = life;
    this.size[i] = size;
    this.grav[i] = gravity;
  }

  update(dt: number): void {
    let active = 0;
    for (let i = 0; i < this.cap; i++) {
      if (this.life[i]! <= 0) continue;
      const l = (this.life[i] -= dt);
      if (l <= 0) {
        this.alpha[i] = 0;
        continue;
      }
      active++;
      const o = i * 3;
      this.vel[o + 1] -= this.grav[i]! * dt;
      this.pos[o] += this.vel[o]! * dt;
      this.pos[o + 1] += this.vel[o + 1]! * dt;
      this.pos[o + 2] += this.vel[o + 2]! * dt;
      if (this.pos[o + 1]! < 0.05 && this.grav[i]! > 0) {
        this.pos[o + 1] = 0.05;
        this.vel[o + 1] *= -0.35;
        this.vel[o] *= 0.6;
        this.vel[o + 2] *= 0.6;
      }
      const k = l / this.maxLife[i]!;
      this.alpha[i] = k < 0.5 ? k * 2 : 1;
    }
    this.active = active;
    const g = this.points.geometry;
    g.attributes.position!.needsUpdate = true;
    g.attributes.aAlpha!.needsUpdate = true;
    g.attributes.aColor!.needsUpdate = true;
    g.attributes.aSize!.needsUpdate = true;
  }

  clear(): void {
    this.life.fill(0);
    this.alpha.fill(0);
  }
}

interface Ring {
  mesh: THREE.Mesh;
  t: number;
  dur: number;
  radius: number;
}

/**
 * Pooled particles and shock rings. Two point clouds (additive glow, opaque
 * debris/confetti) = two draw calls for every effect in the game.
 */
export class Effects {
  readonly group = new THREE.Group();
  private readonly glow: Particles;
  private readonly solid: Particles;
  private readonly rings: Ring[] = [];
  private ringCursor = 0;
  private readonly color = new THREE.Color();

  constructor(maxParticles: number) {
    this.glow = new Particles(Math.round(maxParticles * 0.65), true);
    this.solid = new Particles(Math.round(maxParticles * 0.35), false);
    this.group.add(this.glow.points, this.solid.points);
    const geo = new THREE.RingGeometry(0.82, 1, 40).rotateX(-Math.PI / 2);
    for (let i = 0; i < 14; i++) {
      const mesh = new THREE.Mesh(geo, new THREE.MeshBasicMaterial({ transparent: true, opacity: 0, blending: THREE.AdditiveBlending, depthWrite: false }));
      mesh.visible = false;
      mesh.renderOrder = 4;
      this.group.add(mesh);
      this.rings.push({ mesh, t: 0, dur: 1, radius: 1 });
    }
  }

  get activeParticles(): number {
    return this.glow.active + this.solid.active;
  }

  /** Radial burst. `up` biases the spray upward; `solid` picks the opaque cloud. */
  burst(x: number, y: number, z: number, count: number, color: number, speed: number, life: number, size: number, gravity = 9, up = 0.6, solid = false): void {
    const p = solid ? this.solid : this.glow;
    this.color.setHex(color);
    for (let i = 0; i < count; i++) {
      const a = Math.random() * Math.PI * 2;
      const e = Math.random() * Math.PI - Math.PI / 2;
      const s = speed * (0.35 + Math.random() * 0.65);
      const ce = Math.cos(e);
      p.emit(x, y, z, Math.cos(a) * ce * s, Math.abs(Math.sin(e)) * s * up + s * up * 0.4, Math.sin(a) * ce * s, life * (0.6 + Math.random() * 0.4), size * (0.6 + Math.random() * 0.6), this.color, gravity);
    }
  }

  /** A few slow, short-lived motes (trails, vents). */
  puff(x: number, y: number, z: number, color: number, size: number, life: number, vy = 0.6): void {
    this.color.setHex(color);
    this.glow.emit(x, y, z, (Math.random() - 0.5) * 0.6, vy, (Math.random() - 0.5) * 0.6, life, size, this.color, 0);
  }

  ring(x: number, z: number, color: number, radius: number, dur = 0.45, y = 0.08): void {
    const r = this.rings[this.ringCursor]!;
    this.ringCursor = (this.ringCursor + 1) % this.rings.length;
    r.t = 0;
    r.dur = dur;
    r.radius = radius;
    r.mesh.visible = true;
    r.mesh.position.set(x, y, z);
    (r.mesh.material as THREE.MeshBasicMaterial).color.setHex(color);
  }

  confetti(x: number, y: number, z: number, count: number): void {
    const colors = [0x3fd5ff, 0xffd23a, 0xff4fa0, 0x6dff8a, 0xffffff, 0x8c6bff];
    for (let i = 0; i < count; i++) {
      this.color.setHex(colors[i % colors.length]!);
      this.solid.emit(x + (Math.random() - 0.5) * 7, y + Math.random() * 2, z + (Math.random() - 0.5) * 6,
        (Math.random() - 0.5) * 5, 5 + Math.random() * 7, (Math.random() - 0.5) * 5, 1.8 + Math.random() * 1.4, 0.16 + Math.random() * 0.12, this.color, 7);
    }
  }

  update(dt: number): void {
    this.glow.update(dt);
    this.solid.update(dt);
    for (const r of this.rings) {
      if (!r.mesh.visible) continue;
      r.t += dt;
      const k = r.t / r.dur;
      if (k >= 1) {
        r.mesh.visible = false;
        continue;
      }
      const s = r.radius * (0.15 + 0.85 * (1 - (1 - k) * (1 - k)));
      r.mesh.scale.set(s, 1, s);
      (r.mesh.material as THREE.MeshBasicMaterial).opacity = (1 - k) * 0.9;
    }
  }

  clear(): void {
    this.glow.clear();
    this.solid.clear();
    for (const r of this.rings) r.mesh.visible = false;
  }
}
