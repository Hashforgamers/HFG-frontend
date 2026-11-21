import * as THREE from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';
import { Rng } from '../core/Rng';
import { TRACK_HALF } from '../gameplay/constants';
import type { LevelConfig, WorldId } from '../levels/LevelConfig';
import type { QualityPreset } from '../optimization/QualityManager';
import { THEMES, type Theme } from './Lighting';

const START_Z = -14;

type Placer = (rng: Rng, side: number, z: number, o: THREE.Object3D) => void;

function box(w: number, h: number, d: number, x = 0, y = 0, z = 0): THREE.BufferGeometry {
  return new THREE.BoxGeometry(w, h, d).translate(x, y, z);
}

function merge(list: THREE.BufferGeometry[]): THREE.BufferGeometry {
  const flat = list.map((g) => {
    const n = g.index ? g.toNonIndexed() : g;
    n.deleteAttribute('uv');
    return n;
  });
  return mergeGeometries(flat, false)!;
}

function canvasTexture(w: number, h: number, draw: (g: CanvasRenderingContext2D) => void, repeat = true): THREE.CanvasTexture {
  const canvas = document.createElement('canvas');
  canvas.width = w;
  canvas.height = h;
  draw(canvas.getContext('2d')!);
  const tex = new THREE.CanvasTexture(canvas);
  tex.colorSpace = THREE.SRGBColorSpace;
  if (repeat) tex.wrapS = tex.wrapT = THREE.RepeatWrapping;
  tex.anisotropy = 4;
  return tex;
}

/**
 * The track and the world around it. Everything is built from a few modular
 * pieces (slabs, rails, pylons, per-world prop kits) that are merged or
 * instanced, so a whole world costs a couple of dozen draw calls.
 *
 * Scenery here is procedural geometry, not sculpted models — see
 * docs/UNFINISHED.md.
 */
export class Environment {
  readonly group = new THREE.Group();
  readonly theme: Theme;
  private readonly disposables: { dispose(): void }[] = [];
  private readonly animated: ((time: number, dt: number) => void)[] = [];
  private ambient: THREE.Points | null = null;
  private readonly ambientUniforms = { uTime: { value: 0 }, uOrigin: { value: new THREE.Vector3() } };

  constructor(private readonly level: LevelConfig, private readonly quality: QualityPreset) {
    this.theme = THEMES[level.world];
    this.buildTrack();
    this.buildGround();
    this.buildProps(level.world);
    this.buildAmbient();
  }

  private track<T extends { dispose(): void }>(item: T): T {
    this.disposables.push(item);
    return item;
  }

  private add(geometry: THREE.BufferGeometry, material: THREE.Material): THREE.Mesh {
    const mesh = new THREE.Mesh(this.track(geometry), this.track(material));
    this.group.add(mesh);
    return mesh;
  }

  // --- track ---------------------------------------------------------------

  private buildTrack(): void {
    const { level, theme } = this;
    const end = level.length + 16;
    // floor spans: full width, except where a bridge narrows it or a falling platform replaces it
    const cuts: { z0: number; z1: number; spans: [number, number][] }[] = [];
    for (const o of level.obstacles) {
      if (o.kind === 'bridge') cuts.push({ z0: o.z0, z1: o.z1, spans: [[o.x0, o.x1]] });
      if (o.kind === 'fallingPlatform') {
        const spans: [number, number][] = [];
        if (o.x0 > -TRACK_HALF + 0.1) spans.push([-TRACK_HALF, o.x0]);
        if (o.x1 < TRACK_HALF - 0.1) spans.push([o.x1, TRACK_HALF]);
        cuts.push({ z0: o.z0, z1: o.z1, spans });
      }
    }
    cuts.sort((a, b) => a.z0 - b.z0);
    const slabs: { x0: number; x1: number; z0: number; z1: number }[] = [];
    let z = START_Z;
    for (const cut of cuts) {
      if (cut.z0 > z) slabs.push({ x0: -TRACK_HALF, x1: TRACK_HALF, z0: z, z1: cut.z0 });
      for (const [x0, x1] of cut.spans) slabs.push({ x0, x1, z0: cut.z0, z1: cut.z1 });
      z = Math.max(z, cut.z1);
    }
    slabs.push({ x0: -TRACK_HALF, x1: TRACK_HALF, z0: z, z1: end });

    const positions: number[] = [];
    const uvs: number[] = [];
    const normals: number[] = [];
    const sides: THREE.BufferGeometry[] = [];
    const rails: THREE.BufferGeometry[] = [];
    const glow: THREE.BufferGeometry[] = [];
    for (const s of slabs) {
      const u0 = (s.x0 + TRACK_HALF) / (TRACK_HALF * 2);
      const u1 = (s.x1 + TRACK_HALF) / (TRACK_HALF * 2);
      const quad = [
        [s.x0, -s.z0, u0, s.z0], [s.x1, -s.z0, u1, s.z0], [s.x1, -s.z1, u1, s.z1],
        [s.x0, -s.z0, u0, s.z0], [s.x1, -s.z1, u1, s.z1], [s.x0, -s.z1, u0, s.z1],
      ];
      for (const [x, zz, u, v] of quad) {
        positions.push(x!, 0, zz!);
        uvs.push(u!, v! / 10);
        normals.push(0, 1, 0);
      }
      const w = s.x1 - s.x0;
      const d = s.z1 - s.z0;
      sides.push(box(w, 0.7, d, (s.x0 + s.x1) / 2, -0.36, -(s.z0 + s.z1) / 2));
      for (const edge of [s.x0, s.x1]) {
        const full = Math.abs(Math.abs(edge) - TRACK_HALF) < 0.05;
        // outer edges get a kerb + light strip; cut edges just a warning strip
        if (full) rails.push(box(0.3, 0.42, d, edge + Math.sign(edge) * 0.15, 0.2, -(s.z0 + s.z1) / 2));
        glow.push(box(0.09, 0.05, d, edge + Math.sign(edge) * (full ? 0.15 : -0.1), full ? 0.43 : 0.03, -(s.z0 + s.z1) / 2));
      }
    }
    const top = new THREE.BufferGeometry();
    top.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
    top.setAttribute('normal', new THREE.Float32BufferAttribute(normals, 3));
    top.setAttribute('uv', new THREE.Float32BufferAttribute(uvs, 2));

    const accent = '#' + new THREE.Color(theme.accent).getHexString();
    const map = this.track(canvasTexture(256, 256, (g) => {
      g.fillStyle = theme.track;
      g.fillRect(0, 0, 256, 256);
      // panel seams
      g.strokeStyle = 'rgba(0,0,0,0.22)';
      g.lineWidth = 2;
      for (let y = 0; y <= 256; y += 64) { g.beginPath(); g.moveTo(0, y); g.lineTo(256, y); g.stroke(); }
      for (const x of [64, 192]) { g.beginPath(); g.moveTo(x, 0); g.lineTo(x, 256); g.stroke(); }
      g.fillStyle = 'rgba(255,255,255,0.045)';
      for (let i = 0; i < 40; i++) g.fillRect((i * 97) % 256, (i * 53) % 256, 22, 3);
      // edge bands and centre dashes
      g.fillStyle = theme.trackLine;
      g.globalAlpha = 0.9;
      g.fillRect(8, 0, 5, 256);
      g.fillRect(243, 0, 5, 256);
      g.globalAlpha = 0.55;
      g.fillRect(126, 20, 4, 90);
      g.fillRect(126, 148, 4, 90);
      g.globalAlpha = 1;
    }));
    const emissiveMap = this.track(canvasTexture(256, 256, (g) => {
      g.fillStyle = '#000';
      g.fillRect(0, 0, 256, 256);
      g.fillStyle = accent;
      g.fillRect(8, 0, 5, 256);
      g.fillRect(243, 0, 5, 256);
      g.globalAlpha = 0.6;
      g.fillRect(126, 20, 4, 90);
      g.fillRect(126, 148, 4, 90);
    }));
    const glowing = this.level.world !== 'desert' && this.level.world !== 'frozen';
    this.add(top, new THREE.MeshLambertMaterial({ map, emissiveMap, emissive: 0xffffff, emissiveIntensity: glowing ? 1.4 : 0.25 }));
    this.add(merge(sides), new THREE.MeshLambertMaterial({ color: new THREE.Color(theme.track).multiplyScalar(0.55) }));
    this.add(merge(rails), new THREE.MeshLambertMaterial({ color: new THREE.Color(theme.track).multiplyScalar(1.5) }));
    const strip = new THREE.MeshBasicMaterial({ color: theme.accent });
    this.add(merge(glow), strip);

    // animated direction chevrons down the middle of the road
    const chevrons = this.track(canvasTexture(64, 64, (g) => {
      g.clearRect(0, 0, 64, 64);
      g.strokeStyle = '#fff';
      g.lineWidth = 7;
      g.lineJoin = 'miter';
      g.beginPath();
      g.moveTo(10, 44); g.lineTo(32, 22); g.lineTo(54, 44);
      g.stroke();
    }));
    chevrons.repeat.set(1, end / 5);
    const chevronMat = new THREE.MeshBasicMaterial({
      map: chevrons, color: theme.accent, transparent: true, opacity: 0.32, depthWrite: false, blending: THREE.AdditiveBlending,
    });
    const lane = this.add(new THREE.PlaneGeometry(1.6, end - START_Z).rotateX(-Math.PI / 2), chevronMat);
    lane.position.set(0, 0.025, -(end + START_Z) / 2);
    lane.renderOrder = 1;
    this.animated.push((time) => {
      chevrons.offset.y = time * 0.9;
      strip.color.setHex(theme.accent).multiplyScalar(0.8 + Math.sin(time * 3) * 0.2);
    });

    // support pylons under the deck
    const pylon = this.track(box(1.2, 1, 1.2, 0, -0.5, 0));
    const pylonMat = this.track(new THREE.MeshLambertMaterial({ color: new THREE.Color(theme.track).multiplyScalar(0.4) }));
    const count = Math.floor((end - START_Z) / 22) * 2;
    const pylons = new THREE.InstancedMesh(pylon, pylonMat, count);
    const o = new THREE.Object3D();
    for (let i = 0; i < count; i++) {
      o.position.set((i % 2 ? 1 : -1) * 3.6, -0.7, -(START_Z + 8 + Math.floor(i / 2) * 22));
      o.scale.set(1, Math.min(60, -theme.groundY), 1);
      o.updateMatrix();
      pylons.setMatrixAt(i, o.matrix);
    }
    this.group.add(pylons);

    // boss arena: a wider pad at the end of the road
    const pad = this.add(
      new THREE.CylinderGeometry(9.5, 10.5, 0.7, 24).translate(0, -0.37, -level.length),
      new THREE.MeshLambertMaterial({ color: new THREE.Color(theme.track).multiplyScalar(0.8) }),
    );
    pad.renderOrder = -1;
    const ring = this.add(
      new THREE.RingGeometry(8.6, 9.1, 48).rotateX(-Math.PI / 2).translate(0, 0.02, -level.length),
      new THREE.MeshBasicMaterial({ color: theme.accent2, transparent: true, opacity: 0.8 }),
    );
    this.animated.push((time) => ((ring.material as THREE.MeshBasicMaterial).opacity = 0.55 + Math.sin(time * 2.5) * 0.25));
  }

  private buildGround(): void {
    const { theme, level } = this;
    const len = level.length + 260;
    if (level.world === 'volcanic') {
      // lava: two scrolling noise layers, bright cracks over dark crust
      const uniforms = { uTime: { value: 0 }, fogColor: { value: new THREE.Color(theme.fog) }, fogNear: { value: theme.fogNear }, fogFar: { value: theme.fogFar } };
      const mat = new THREE.ShaderMaterial({
        uniforms,
        vertexShader: /* glsl */ `varying vec2 vP; varying float vDepth;
          void main(){ vec4 w = modelMatrix * vec4(position,1.0); vP = w.xz; vec4 mv = viewMatrix * w; vDepth = -mv.z; gl_Position = projectionMatrix * mv; }`,
        fragmentShader: /* glsl */ `uniform float uTime; uniform vec3 fogColor; uniform float fogNear; uniform float fogFar;
          varying vec2 vP; varying float vDepth;
          float hash(vec2 p){ return fract(sin(dot(p, vec2(127.1,311.7))) * 43758.5453); }
          float noise(vec2 p){ vec2 i=floor(p), f=fract(p); f=f*f*(3.0-2.0*f);
            return mix(mix(hash(i),hash(i+vec2(1,0)),f.x), mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x), f.y); }
          void main(){
            vec2 p = vP * 0.11;
            float n = noise(p + vec2(0.0, uTime*0.05)) * 0.6 + noise(p*2.3 - vec2(uTime*0.04, 0.0)) * 0.4;
            float crack = smoothstep(0.42, 0.62, n);
            vec3 col = mix(vec3(0.07,0.02,0.015), vec3(1.0,0.36,0.05), crack);
            col += vec3(1.0,0.85,0.3) * smoothstep(0.72, 0.9, n);
            float fog = smoothstep(fogNear, fogFar, vDepth);
            gl_FragColor = vec4(mix(col, fogColor, fog), 1.0);
            #include <colorspace_fragment>
          }`,
      });
      const lava = this.add(new THREE.PlaneGeometry(260, len).rotateX(-Math.PI / 2), mat);
      lava.position.set(0, theme.groundY, -level.length / 2);
      this.animated.push((time) => (uniforms.uTime.value = time));
      return;
    }
    const tex = this.track(canvasTexture(128, 128, (g) => {
      const base = new THREE.Color(theme.ground);
      g.fillStyle = '#' + base.getHexString();
      g.fillRect(0, 0, 128, 128);
      if (level.world === 'neon' || level.world === 'cyber') {
        g.strokeStyle = '#' + new THREE.Color(theme.accent).multiplyScalar(0.5).getHexString();
        g.lineWidth = 2;
        g.strokeRect(0, 0, 128, 128);
      } else {
        for (let i = 0; i < 220; i++) {
          g.fillStyle = i % 2 ? 'rgba(255,255,255,0.06)' : 'rgba(0,0,0,0.05)';
          g.fillRect((i * 71) % 128, (i * 37) % 128, 10 + (i % 5) * 4, 2);
        }
      }
    }));
    tex.repeat.set(40, len / 6);
    const ground = this.add(new THREE.PlaneGeometry(260, len).rotateX(-Math.PI / 2), new THREE.MeshLambertMaterial({ map: tex }));
    ground.position.set(0, theme.groundY, -level.length / 2);
  }

  // --- scenery kits ----------------------------------------------------------

  /** Scatter `count` instances of one prop along both sides of the track. */
  private scatter(geometry: THREE.BufferGeometry, material: THREE.Material, count: number, rng: Rng, place: Placer, colors?: number[]): void {
    const n = Math.max(1, Math.round(count * this.quality.propDensity));
    const mesh = new THREE.InstancedMesh(this.track(geometry), this.track(material), n);
    const o = new THREE.Object3D();
    const c = new THREE.Color();
    const span = this.level.length + 110;
    for (let i = 0; i < n; i++) {
      o.position.set(0, 0, 0);
      o.rotation.set(0, 0, 0);
      o.scale.set(1, 1, 1);
      // stratified along the track so there are no bare stretches
      place(rng, i % 2 ? 1 : -1, START_Z - 6 + ((i + rng.next()) / n) * span, o);
      o.updateMatrix();
      mesh.setMatrixAt(i, o.matrix);
      if (colors) mesh.setColorAt(i, c.setHex(rng.pick(colors)));
    }
    this.group.add(mesh);
  }

  private buildProps(world: WorldId): void {
    const { theme } = this;
    const rng = new Rng(this.level.seed * 31 + 7);
    const gy = theme.groundY;
    const flat = (color: number, extra: THREE.MeshLambertMaterialParameters = {}) => new THREE.MeshLambertMaterial({ color, flatShading: true, ...extra });
    const basic = (color: number) => new THREE.MeshBasicMaterial({ color });
    const lit = (color: number, opacity = 0.9) =>
      new THREE.MeshBasicMaterial({ color, transparent: true, opacity, blending: THREE.AdditiveBlending, depthWrite: false, side: THREE.DoubleSide });
    const far = (rng2: Rng, side: number, min: number, max: number) => side * rng2.range(min, max);

    if (world === 'neon') {
      // light gantries over the highway, alternating blue and red
      // light pylons lean in over the highway (never across it: the camera flies above the road)
      const pylon = merge([box(0.35, 7, 0.35, 0, 3.5, 0), box(2.6, 0.3, 0.4, -1.15, 7, 0), box(0.7, 0.5, 0.7, 0, 0.25, 0)]);
      this.scatter(pylon, flat(0x3a4066), 24, rng, (_r, s, z, o) => { o.position.set(s * 6.5, 0, -Math.round(z / 14) * 14); o.scale.x = s; });
      for (const [color, phase] of [[theme.accent, 0], [theme.accent2, 14]] as const) {
        this.scatter(box(2.0, 0.1, 0.24, -1.3, 6.8, 0), basic(color), 12, rng, (_r, s, z, o) => { o.position.set(s * 6.5, 0, -Math.round(z / 28) * 28 - phase); o.scale.x = s; });
      }
      // industrial barriers and containers alongside
      const barrier = merge([box(2.4, 1.0, 0.7, 0, 0.5, 0), box(2.6, 0.2, 0.9, 0, 1.1, 0)]);
      this.scatter(barrier, flat(0xffffff), 60, rng, (r, s, z, o) => { o.position.set(far(r, s, 7.2, 8.4), gy + 7, -z); o.rotation.y = r.range(-0.1, 0.1); }, [0x3b4263, 0x2c3350, 0x55406e]);
      this.scatter(box(1, 1, 1, 0, 0.5, 0), flat(0xffffff), 70, rng, (r, s, z, o) => {
        o.position.set(far(r, s, 11, 46), gy, -z);
        o.scale.set(r.range(3, 8), r.range(5, 26), r.range(3, 8));
      }, [0x161b33, 0x1d1740, 0x10203a]);
      // billboards
      this.scatter(new THREE.PlaneGeometry(5, 2.6), lit(0xffffff, 0.75), 16, rng, (r, s, z, o) => {
        o.position.set(far(r, s, 9, 20), r.range(3, 12), -z);
        o.rotation.y = -s * r.range(0.5, 1.1);
      }, [theme.accent, theme.accent2, 0x9d6bff]);
    } else if (world === 'desert') {
      const sand = [0xcfa46a, 0xb98d55, 0xe0bb80];
      const column = merge([new THREE.CylinderGeometry(0.75, 0.9, 7, 8).translate(0, 3.5, 0), box(2.2, 0.5, 2.2, 0, 7.25, 0), box(2.4, 0.5, 2.4, 0, 0.25, 0)]);
      this.scatter(column, flat(0xffffff), 34, rng, (r, s, z, o) => {
        o.position.set(far(r, s, 7.5, 20), gy, -z);
        o.scale.y = r.next() < 0.4 ? r.range(0.3, 0.6) : r.range(0.9, 1.5); // some are broken stumps
        o.rotation.z = r.range(-0.06, 0.06);
      }, sand);
      const arch = merge([box(1.6, 9, 1.6, -4, 4.5, 0), box(1.6, 9, 1.6, 4, 4.5, 0), box(11, 1.6, 2, 0, 9.8, 0), box(8, 0.8, 1.6, 0, 11, 0)]);
      this.scatter(arch, flat(0xffffff), 8, rng, (r, s, z, o) => { o.position.set(far(r, s, 14, 30), gy, -z); o.rotation.y = r.range(0, 3); o.scale.setScalar(r.range(0.9, 1.6)); }, sand);
      this.scatter(new THREE.DodecahedronGeometry(1, 0), flat(0xffffff), 70, rng, (r, s, z, o) => {
        o.position.set(far(r, s, 7, 50), gy, -z);
        o.scale.set(r.range(1, 4), r.range(0.8, 3), r.range(1, 4));
        o.rotation.set(r.next(), r.next() * 3, r.next());
      }, [0x9b7446, 0xb08a58, 0x7f5d38]);
      // mesas on the horizon
      this.scatter(new THREE.CylinderGeometry(0.7, 1, 1, 7).translate(0, 0.5, 0), flat(0xffffff), 14, rng, (r, s, z, o) => {
        o.position.set(far(r, s, 48, 95), gy, -z);
        o.scale.set(r.range(14, 30), r.range(14, 34), r.range(14, 30));
      }, [0xb5764a, 0xa3643d]);
      // mechanical ruins: half-buried gears and a fallen strut
      this.scatter(new THREE.TorusGeometry(4, 0.9, 6, 14), flat(0x4f5560), 10, rng, (r, s, z, o) => {
        o.position.set(far(r, s, 10, 34), gy + r.range(-1, 1.5), -z);
        o.rotation.set(r.range(0.2, 1.2), r.next() * 3, r.range(-0.4, 0.4));
        o.scale.setScalar(r.range(0.6, 1.5));
      });
      this.scatter(box(1.2, 1.2, 14), flat(0x5d636e), 8, rng, (r, s, z, o) => { o.position.set(far(r, s, 9, 30), gy + 1.5, -z); o.rotation.set(r.range(-0.5, 0.5), r.next() * 3, 0); });
    } else if (world === 'frozen') {
      const ice = new THREE.MeshLambertMaterial({ color: 0xffffff, flatShading: true, emissive: 0x2a6fb0, emissiveIntensity: 0.55, transparent: true, opacity: 0.9 });
      this.scatter(new THREE.OctahedronGeometry(1, 0), ice, 60, rng, (r, s, z, o) => {
        o.position.set(far(r, s, 7, 36), gy + r.range(0, 1.5), -z);
        o.scale.set(r.range(0.8, 2.2), r.range(3, 9), r.range(0.8, 2.2));
        o.rotation.set(r.range(-0.3, 0.3), r.next() * 3, r.range(-0.3, 0.3));
      }, [0xbfe9ff, 0x8fd0ff, 0xe6f8ff]);
      // fortress wall with crenellations, running along both sides
      const wall = merge([box(11, 7, 2.4, 0, 3.5, 0), ...[-4, -1.35, 1.35, 4].map((x) => box(1.6, 1.2, 2.4, x, 7.6, 0)), box(3.4, 10.5, 3.4, 5.6, 5.25, 0), box(4, 0.8, 4, 5.6, 10.9, 0)]);
      this.scatter(wall, flat(0xffffff), 22, rng, (r, s, z, o) => { o.position.set(s * r.range(13, 15), gy, -Math.round(z / 11) * 11); o.rotation.y = s * Math.PI / 2; }, [0x8aa6c7, 0x9db7d6]);
      // frozen gates: ice arches spanning the road
      const gate = merge([box(1.6, 20, 1.6, -7, 10, 0), box(1.6, 20, 1.6, 7, 10, 0), box(15.6, 1.4, 1.8, 0, 20.4, 0), ...[-4.5, -1.5, 1.5, 4.5].map((x) => new THREE.ConeGeometry(0.5, 2.6, 5).rotateX(Math.PI).translate(x, 18.5, 0))]);
      this.scatter(gate, ice, 5, rng, (_r, _s, z, o) => o.position.set(0, 0, -Math.round(z / 40) * 40 - 20), [0xcff0ff]);
      const pine = merge([new THREE.CylinderGeometry(0.25, 0.3, 1.2, 6).translate(0, 0.6, 0), new THREE.ConeGeometry(1.7, 2.6, 7).translate(0, 2.3, 0), new THREE.ConeGeometry(1.3, 2.3, 7).translate(0, 3.8, 0), new THREE.ConeGeometry(0.8, 2, 7).translate(0, 5.1, 0)]);
      this.scatter(pine, flat(0xffffff), 60, rng, (r, s, z, o) => { o.position.set(far(r, s, 18, 60), gy, -z); o.scale.setScalar(r.range(0.8, 1.8)); }, [0xdfeefa, 0xc4dcf0, 0x9fc2de]);
      this.scatter(new THREE.SphereGeometry(1, 8, 5), flat(0xf4f9ff), 40, rng, (r, s, z, o) => { o.position.set(far(r, s, 7, 40), gy - 0.3, -z); o.scale.set(r.range(2, 7), r.range(0.8, 2), r.range(2, 7)); });
    } else if (world === 'cyber') {
      // skyscrapers with lit windows
      const windows = this.track(canvasTexture(64, 128, (g) => {
        g.fillStyle = '#05040c';
        g.fillRect(0, 0, 64, 128);
        for (let y = 4; y < 128; y += 8) for (let x = 4; x < 64; x += 8) {
          const v = Math.sin(x * 12.9 + y * 78.2) * 43758.5;
          const k = v - Math.floor(v);
          if (k > 0.45) { g.fillStyle = k > 0.85 ? '#ff7be6' : k > 0.65 ? '#5ff2ff' : '#3a2c6e'; g.fillRect(x, y, 4, 5); }
        }
      }));
      const tower = new THREE.BoxGeometry(1, 1, 1).translate(0, 0.5, 0);
      const towerMat = new THREE.MeshLambertMaterial({ color: 0x15102a, emissive: 0xffffff, emissiveMap: windows, emissiveIntensity: 1.5 });
      this.scatter(tower, towerMat, 90, rng, (r, s, z, o) => {
        o.position.set(far(r, s, 10, 70), gy, -z);
        o.scale.set(r.range(5, 12), r.range(34, 78), r.range(5, 12));
      });
      // holographic adverts: flickering additive panels and rings
      const holoA = lit(0xffffff, 0.6);
      const holoB = lit(theme.accent2, 0.55);
      this.scatter(new THREE.PlaneGeometry(6, 3.4), holoA, 22, rng, (r, s, z, o) => { o.position.set(far(r, s, 8.5, 22), r.range(2, 16), -z); o.rotation.y = -s * r.range(0.4, 1.2); }, [theme.accent, theme.accent2, 0xffe14f]);
      this.scatter(new THREE.TorusGeometry(2.2, 0.08, 6, 28), holoB, 12, rng, (r, s, z, o) => { o.position.set(far(r, s, 9, 18), r.range(4, 14), -z); o.rotation.set(r.next() * 3, r.next() * 3, 0); });
      this.animated.push((time) => {
        holoA.opacity = 0.5 + (Math.sin(time * 9) > 0.92 ? -0.3 : 0) + Math.sin(time * 1.7) * 0.1;
        holoB.opacity = 0.4 + Math.sin(time * 2.3) * 0.2;
      });
      // light rails on the elevated track's flanks
      this.scatter(merge([box(0.3, 3, 0.3, 0, 1.5, 0), box(1.6, 0.25, 0.3, 0.65, 3, 0)]), flat(0x2a2146), 30, rng, (_r, s, z, o) => { o.position.set(s * 6, 0, -Math.round(z / 12) * 12); o.scale.x = -s; });
      this.scatter(box(0.9, 0.1, 0.34, 0, 2.86, 0), basic(theme.accent2), 30, rng, (_r, s, z, o) => o.position.set(s * 5.1, 0, -Math.round(z / 12) * 12));
    } else {
      // volcanic: basalt, industrial platforms, pipes and glowing vents
      this.scatter(new THREE.CylinderGeometry(1, 1.15, 1, 6).translate(0, 0.5, 0), flat(0xffffff), 90, rng, (r, s, z, o) => {
        o.position.set(far(r, s, 7.5, 50), gy - 1, -z);
        o.scale.set(r.range(1.2, 3.4), r.range(3, 15), r.range(1.2, 3.4));
        o.rotation.y = r.next() * 3;
      }, [0x1d1716, 0x2a2120, 0x130f0f]);
      const platform = merge([box(9, 0.6, 7, 0, 5.3, 0), ...[[-4, -3], [4, -3], [-4, 3], [4, 3]].map(([x, z]) => box(0.6, 5.2, 0.6, x!, 2.6, z!)), box(3.4, 3.6, 3.4, -1.6, 7.4, 0), new THREE.CylinderGeometry(1.2, 1.2, 4.6, 10).translate(2.4, 7.9, 0)]);
      this.scatter(platform, flat(0xffffff), 12, rng, (r, s, z, o) => { o.position.set(far(r, s, 13, 30), gy, -z); o.rotation.y = r.next() * 3; }, [0x4a4744, 0x3a3836, 0x5a4a40]);
      this.scatter(new THREE.CylinderGeometry(0.5, 0.5, 26, 8).rotateX(Math.PI / 2), flat(0x54504c), 14, rng, (r, s, z, o) => { o.position.set(far(r, s, 8, 12), gy + r.range(1.5, 4), -z); });
      const vent = lit(theme.accent, 0.95);
      this.scatter(new THREE.CylinderGeometry(0.9, 1.3, 0.5, 8), vent, 30, rng, (r, s, z, o) => { o.position.set(far(r, s, 7.5, 34), gy + 0.3, -z); o.scale.setScalar(r.range(0.7, 2)); });
      // glowing seams on the deck's flanks
      this.scatter(box(0.2, 0.5, 5, 0, -0.4, 0), basic(theme.accent), 40, rng, (_r, s, z, o) => o.position.set(s * 5.02, 0, -Math.round(z / 8) * 8));
      this.animated.push((time) => (vent.opacity = 0.7 + Math.sin(time * 4.3) * 0.25));
    }
  }

  // --- ambient particles -------------------------------------------------------

  private buildAmbient(): void {
    const n = this.quality.ambientParticles;
    if (n === 0) return;
    const { theme } = this;
    const pos = new Float32Array(n * 3);
    const seed = new Float32Array(n);
    const rng = new Rng(99);
    for (let i = 0; i < n; i++) {
      pos[i * 3] = rng.range(0, 1);
      pos[i * 3 + 1] = rng.range(0, 1);
      pos[i * 3 + 2] = rng.range(0, 1);
      seed[i] = rng.next();
    }
    const geo = this.track(new THREE.BufferGeometry());
    geo.setAttribute('position', new THREE.BufferAttribute(pos, 3));
    geo.setAttribute('aSeed', new THREE.BufferAttribute(seed, 1));
    const drift: Record<Theme['ambient'], [number, number, number]> = { specks: [0.2, 0.25, 0], dust: [1.2, 0.1, 0.3], snow: [0.5, -1.6, 0.2], embers: [0.3, 1.5, 0] };
    const mat = this.track(new THREE.ShaderMaterial({
      uniforms: { ...this.ambientUniforms, uColor: { value: new THREE.Color(theme.ambientColor) }, uDrift: { value: new THREE.Vector3(...drift[theme.ambient]) } },
      transparent: true,
      depthWrite: false,
      blending: theme.ambient === 'snow' || theme.ambient === 'dust' ? THREE.NormalBlending : THREE.AdditiveBlending,
      // the cloud is a box that wraps around the camera, entirely on the GPU
      vertexShader: /* glsl */ `attribute float aSeed; uniform float uTime; uniform vec3 uOrigin; uniform vec3 uDrift; varying float vA;
        void main(){
          vec3 size = vec3(34.0, 16.0, 60.0);
          vec3 p = position * size + uDrift * uTime * (0.5 + aSeed);
          p.x += sin(uTime * 0.7 + aSeed * 40.0) * 0.6;
          p = mod(p - uOrigin, size) - size * vec3(0.5, 0.2, 0.85) + uOrigin;
          vec4 mv = viewMatrix * vec4(p, 1.0);
          gl_Position = projectionMatrix * mv;
          gl_PointSize = (2.0 + aSeed * 5.0) * (30.0 / -mv.z);
          vA = 0.35 + 0.5 * aSeed;
        }`,
      fragmentShader: /* glsl */ `uniform vec3 uColor; varying float vA;
        void main(){ float d = length(gl_PointCoord - 0.5); if (d > 0.5) discard; gl_FragColor = vec4(uColor, vA * smoothstep(0.5, 0.1, d));
        #include <colorspace_fragment>
        }`,
    }));
    this.ambient = new THREE.Points(geo, mat);
    this.ambient.frustumCulled = false;
    this.group.add(this.ambient);
  }

  update(time: number, dt: number, camera: THREE.Vector3): void {
    for (const fn of this.animated) fn(time, dt);
    this.ambientUniforms.uTime.value = time;
    this.ambientUniforms.uOrigin.value.copy(camera);
  }

  dispose(): void {
    for (const d of this.disposables) d.dispose();
    this.group.removeFromParent();
  }
}
