import * as THREE from 'three';
import type { WorldId } from '../levels/LevelConfig';

export interface Theme {
  skyTop: number;
  skyBottom: number;
  fog: number;
  fogNear: number;
  fogFar: number;
  sun: number;
  sunIntensity: number;
  hemiSky: number;
  hemiGround: number;
  hemiIntensity: number;
  track: string;
  trackLine: string;
  /** Accent used for rails, edge lights and markings. */
  accent: number;
  accent2: number;
  ground: number;
  groundY: number;
  ambient: 'specks' | 'dust' | 'snow' | 'embers';
  ambientColor: number;
}

export const THEMES: Record<WorldId, Theme> = {
  neon: {
    skyTop: 0x05060f, skyBottom: 0x1b1147, fog: 0x120c33, fogNear: 45, fogFar: 150,
    sun: 0xdfe8ff, sunIntensity: 2.6, hemiSky: 0x9fb4ff, hemiGround: 0x4a2a6c, hemiIntensity: 2.4,
    track: '#232a47', trackLine: '#3fd5ff', accent: 0x2fd0ff, accent2: 0xff3a5e,
    ground: 0x080a16, groundY: -7, ambient: 'specks', ambientColor: 0x6fd8ff,
  },
  desert: {
    skyTop: 0x3f8fd6, skyBottom: 0xf6cf94, fog: 0xeec58c, fogNear: 55, fogFar: 170,
    sun: 0xfff0cf, sunIntensity: 2.3, hemiSky: 0xbfdcff, hemiGround: 0xb9824a, hemiIntensity: 1.25,
    track: '#b8925e', trackLine: '#f5e2b4', accent: 0xffc35a, accent2: 0x2f9bd8,
    ground: 0xd9a865, groundY: -5, ambient: 'dust', ambientColor: 0xfff0cf,
  },
  frozen: {
    skyTop: 0x1c3f78, skyBottom: 0xbfe2ff, fog: 0xaed3f5, fogNear: 40, fogFar: 150,
    sun: 0xe6f3ff, sunIntensity: 1.9, hemiSky: 0xcfe8ff, hemiGround: 0x5f86b8, hemiIntensity: 1.45,
    track: '#6f93bd', trackLine: '#e8f7ff', accent: 0x9fe6ff, accent2: 0x3a7dff,
    ground: 0xe6f1fb, groundY: -5, ambient: 'snow', ambientColor: 0xffffff,
  },
  cyber: {
    skyTop: 0x070418, skyBottom: 0x3a0f5e, fog: 0x250a45, fogNear: 40, fogFar: 140,
    sun: 0xf0dcff, sunIntensity: 2.4, hemiSky: 0xd09cff, hemiGround: 0x2b4a7a, hemiIntensity: 2.3,
    track: '#2a2248', trackLine: '#ff4fd8', accent: 0xff4fd8, accent2: 0x35f0ff,
    ground: 0x06030f, groundY: -40, ambient: 'specks', ambientColor: 0xff8cf0,
  },
  volcanic: {
    skyTop: 0x120505, skyBottom: 0x6a1a08, fog: 0x3a0f08, fogNear: 38, fogFar: 135,
    sun: 0xffe0c0, sunIntensity: 2.6, hemiSky: 0xffb48a, hemiGround: 0x7a2a15, hemiIntensity: 2.2,
    track: '#3a3232', trackLine: '#ff8a2a', accent: 0xff7a1e, accent2: 0xffd23a,
    ground: 0x1a0b08, groundY: -5, ambient: 'embers', ambientColor: 0xffa040,
  },
};

/** Sky gradient, fog and the two lights that every world shares (no shadow maps — units get blob shadows). */
export class Lighting {
  readonly hemi = new THREE.HemisphereLight();
  readonly sun = new THREE.DirectionalLight();
  private sky: THREE.Texture | null = null;

  constructor(private readonly scene: THREE.Scene) {
    this.sun.position.set(-6, 14, 8);
    scene.add(this.hemi, this.sun);
  }

  apply(theme: Theme): void {
    this.hemi.color.setHex(theme.hemiSky);
    this.hemi.groundColor.setHex(theme.hemiGround);
    this.hemi.intensity = theme.hemiIntensity;
    this.sun.color.setHex(theme.sun);
    this.sun.intensity = theme.sunIntensity;
    this.scene.fog = new THREE.Fog(theme.fog, theme.fogNear, theme.fogFar);

    const canvas = document.createElement('canvas');
    canvas.width = 4;
    canvas.height = 256;
    const g = canvas.getContext('2d')!;
    const grad = g.createLinearGradient(0, 0, 0, 256);
    grad.addColorStop(0, '#' + new THREE.Color(theme.skyTop).getHexString());
    grad.addColorStop(0.55, '#' + new THREE.Color(theme.skyBottom).getHexString());
    grad.addColorStop(1, '#' + new THREE.Color(theme.fog).getHexString());
    g.fillStyle = grad;
    g.fillRect(0, 0, 4, 256);
    this.sky?.dispose();
    this.sky = new THREE.CanvasTexture(canvas);
    this.sky.colorSpace = THREE.SRGBColorSpace;
    this.scene.background = this.sky;
  }
}
