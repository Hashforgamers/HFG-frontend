import * as THREE from 'three';
import { GLTFLoader } from 'three/examples/jsm/loaders/GLTFLoader.js';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';

export const PART_NAMES = ['torso', 'armL', 'armR', 'legL', 'legR', 'head'] as const;

/** A character flattened into one geometry for instancing. */
export interface BotModel {
  /** position, normal, color, aEmit (1 = glows), aPart (index into PART_NAMES). */
  geometry: THREE.BufferGeometry;
  /** Joint position of each part, model space. */
  pivots: THREE.Vector3[];
  triangles: number;
}

export const MODEL_NAMES = [
  'blue_bot', 'blue_bot_lo', 'red_grunt', 'red_grunt_lo', 'red_brute', 'red_brute_lo',
  'boss_titan', 'boss_inferno', 'boss_void', 'cannon', 'turret', 'barrel',
] as const;
export type ModelName = (typeof MODEL_NAMES)[number];

function partIndex(node: THREE.Object3D): { index: number; node: THREE.Object3D } {
  for (let n: THREE.Object3D | null = node; n; n = n.parent) {
    const index = PART_NAMES.findIndex((p) => n!.name === p || n!.name.startsWith(p + '_'));
    if (index >= 0 && (PART_NAMES as readonly string[]).includes(n.name)) return { index, node: n };
    if (index >= 0 && !n.parent?.name.startsWith(PART_NAMES[index]!)) return { index, node: n };
  }
  return { index: 0, node };
}

/** Loads the GLB models produced by tools/build_assets.py. */
export class AssetManager {
  private readonly scenes = new Map<ModelName, THREE.Group>();
  private readonly bots = new Map<ModelName, BotModel>();
  /** Total model download + parse time, ms. */
  loadMs = 0;

  async load(base: string, onProgress: (fraction: number) => void): Promise<void> {
    const start = performance.now();
    const loader = new GLTFLoader();
    let done = 0;
    await Promise.all(
      MODEL_NAMES.map(async (name) => {
        const gltf = await loader.loadAsync(`${base}models/${name}.glb`);
        gltf.scene.updateMatrixWorld(true);
        this.scenes.set(name, gltf.scene);
        onProgress(++done / MODEL_NAMES.length);
      }),
    );
    this.loadMs = performance.now() - start;
  }

  /** Fresh copy of a model with its own materials (so it can flash / fade independently). */
  model(name: ModelName): THREE.Group {
    const scene = this.scenes.get(name);
    if (!scene) throw new Error(`model not loaded: ${name}`);
    const copy = scene.clone(true);
    const cloned = new Map<THREE.Material, THREE.Material>();
    copy.traverse((o) => {
      const mesh = o as THREE.Mesh;
      if (!mesh.isMesh) return;
      const mat = mesh.material as THREE.Material;
      if (!cloned.has(mat)) cloned.set(mat, mat.clone());
      mesh.material = cloned.get(mat)!;
    });
    return copy;
  }

  /**
   * Bake a multi-part, multi-material character into a single geometry:
   * materials become vertex colours (+ an emissive flag) and every vertex is
   * tagged with its part, so the crowd shader can swing limbs on the GPU.
   */
  bot(name: ModelName): BotModel {
    const cached = this.bots.get(name);
    if (cached) return cached;
    const scene = this.scenes.get(name);
    if (!scene) throw new Error(`model not loaded: ${name}`);
    const pieces: THREE.BufferGeometry[] = [];
    const pivots = PART_NAMES.map(() => new THREE.Vector3());
    scene.traverse((o) => {
      const mesh = o as THREE.Mesh;
      if (!mesh.isMesh) return;
      const part = partIndex(mesh);
      part.node.getWorldPosition(pivots[part.index]!);
      const mat = mesh.material as THREE.MeshStandardMaterial;
      const src = mesh.geometry.index ? mesh.geometry.toNonIndexed() : mesh.geometry.clone();
      src.applyMatrix4(mesh.matrixWorld);
      const n = src.attributes.position!.count;
      const geo = new THREE.BufferGeometry();
      geo.setAttribute('position', src.attributes.position!);
      geo.setAttribute('normal', src.attributes.normal!);
      const color = new Float32Array(n * 3);
      const emit = new Float32Array(n);
      const partAttr = new Float32Array(n).fill(part.index);
      const glows = mat.emissive && mat.emissive.r + mat.emissive.g + mat.emissive.b > 0.01;
      for (let i = 0; i < n; i++) {
        color[i * 3] = mat.color.r;
        color[i * 3 + 1] = mat.color.g;
        color[i * 3 + 2] = mat.color.b;
        emit[i] = glows ? 1 : 0;
      }
      geo.setAttribute('color', new THREE.BufferAttribute(color, 3));
      geo.setAttribute('aEmit', new THREE.BufferAttribute(emit, 1));
      geo.setAttribute('aPart', new THREE.BufferAttribute(partAttr, 1));
      pieces.push(geo);
    });
    const geometry = mergeGeometries(pieces, false)!;
    geometry.computeBoundingSphere();
    const model: BotModel = { geometry, pivots, triangles: geometry.attributes.position!.count / 3 };
    this.bots.set(name, model);
    return model;
  }
}
