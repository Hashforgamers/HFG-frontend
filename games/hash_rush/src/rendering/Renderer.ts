import * as THREE from 'three';
import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
import { OutputPass } from 'three/examples/jsm/postprocessing/OutputPass.js';
import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/examples/jsm/postprocessing/UnrealBloomPass.js';

export interface RenderStats {
  drawCalls: number;
  triangles: number;
  geometries: number;
  textures: number;
  pixelRatio: number;
  width: number;
  height: number;
}

/** Thin wrapper around WebGLRenderer: sizing, pixel ratio, context loss, stats. */
export class Renderer {
  readonly gl: THREE.WebGLRenderer;
  readonly scene = new THREE.Scene();
  private width = 1;
  private height = 1;
  private pixelRatio = 1;
  contextLost = false;
  private composer: EffectComposer | null = null;
  private renderPass: RenderPass | null = null;
  private bloomOn = false;

  constructor(readonly canvas: HTMLCanvasElement, antialias: boolean) {
    this.gl = new THREE.WebGLRenderer({ canvas, antialias, alpha: false, powerPreference: 'high-performance', stencil: false });
    this.gl.outputColorSpace = THREE.SRGBColorSpace;
    this.gl.toneMapping = THREE.ACESFilmicToneMapping;
    this.gl.toneMappingExposure = 1.15;
    // the composer renders several passes per frame; stats are reset by hand once per frame
    this.gl.info.autoReset = false;
    canvas.addEventListener('webglcontextlost', (e) => {
      e.preventDefault();
      this.contextLost = true;
    });
    canvas.addEventListener('webglcontextrestored', () => {
      this.contextLost = false;
    });
  }

  static supported(): boolean {
    try {
      const c = document.createElement('canvas');
      return !!c.getContext('webgl2');
    } catch {
      return false;
    }
  }

  resize(width: number, height: number, pixelRatio: number): boolean {
    const w = Math.max(1, Math.floor(width));
    const h = Math.max(1, Math.floor(height));
    if (w === this.width && h === this.height && Math.abs(pixelRatio - this.pixelRatio) < 0.01) return false;
    this.width = w;
    this.height = h;
    this.pixelRatio = pixelRatio;
    this.gl.setPixelRatio(pixelRatio);
    this.gl.setSize(w, h, false);
    this.composer?.setPixelRatio(pixelRatio);
    this.composer?.setSize(w, h);
    return true;
  }

  /**
   * Bloom: a restrained glow on emissive parts (gates, visors, lava, lasers).
   * Runs at half resolution; needs float render targets, so it quietly stays
   * off where the GPU cannot provide them.
   */
  setBloom(on: boolean): void {
    this.bloomOn = on && this.gl.capabilities.isWebGL2 && !!this.gl.extensions.get('EXT_color_buffer_float');
    if (!this.bloomOn) {
      this.composer?.dispose();
      this.composer = null;
      return;
    }
    if (this.composer) return;
    const target = new THREE.WebGLRenderTarget(this.width, this.height, { type: THREE.HalfFloatType, samples: 2 });
    this.composer = new EffectComposer(this.gl, target);
    this.renderPass = new RenderPass(this.scene, new THREE.PerspectiveCamera());
    this.composer.addPass(this.renderPass);
    this.composer.addPass(new UnrealBloomPass(new THREE.Vector2(this.width / 2, this.height / 2), 0.42, 0.55, 0.82));
    this.composer.addPass(new OutputPass());
    this.composer.setPixelRatio(this.pixelRatio);
    this.composer.setSize(this.width, this.height);
  }

  render(camera: THREE.Camera): void {
    if (this.contextLost) return;
    if (this.composer && this.renderPass) {
      this.renderPass.camera = camera;
      this.composer.render();
    } else {
      this.gl.render(this.scene, camera);
    }
  }

  stats(): RenderStats {
    const info = this.gl.info;
    const out = {
      drawCalls: info.render.calls,
      triangles: info.render.triangles,
      geometries: info.memory.geometries,
      textures: info.memory.textures,
      pixelRatio: this.pixelRatio,
      width: this.width,
      height: this.height,
    };
    info.reset();
    return out;
  }
}
